//
//  LiveMeetingViewModel.swift
//  Granola
//

import Foundation
import SwiftUI
import AVFoundation
import OSLog

@MainActor
@Observable
public final class LiveMeetingViewModel {
    public var state: MeetingState = .idle
    public var meetingID: UUID = UUID()
    public var meetingTitle: String = "Untitled Meeting"
    public var userNotes: String = ""
    public var selectedRecipe: AIRecipe = .standard
    public var audioLevel: AudioLevel = .zero
    public var liveSegments: [TranscriptSegment] = []
    public var durationElapsed: TimeInterval = 0
    public var errorMessage: String?
    
    private let audioManager: AudioCaptureManager
    private let transcriber: StreamingTranscriber
    private let aiService: AIService
    private let repository: LocalMeetingRepository
    
    private var levelTask: Task<Void, Never>?
    private var bufferTask: Task<Void, Never>?
    private var transcriptTask: Task<Void, Never>?
    private var timerTask: Task<Void, Never>?
    private var startTime: Date?
    
    public init(
        audioManager: AudioCaptureManager = DependencyContainer.shared.audioCaptureManager,
        transcriber: StreamingTranscriber = DependencyContainer.shared.streamingTranscriber,
        aiService: AIService = DependencyContainer.shared.aiService,
        repository: LocalMeetingRepository = DependencyContainer.shared.meetingRepository
    ) {
        self.audioManager = audioManager
        self.transcriber = transcriber
        self.aiService = aiService
        self.repository = repository
    }
    
    public func startMeeting(title: String = "Untitled Meeting", recipe: AIRecipe = .standard) async {
        guard state == .idle || state == .completed else { return }
        
        self.meetingID = UUID()
        self.meetingTitle = title.isEmpty ? "Meeting — \(Date().formatted(date: .abbreviated, time: .shortened))" : title
        self.selectedRecipe = recipe
        self.userNotes = ""
        self.liveSegments = []
        self.durationElapsed = 0
        let meetingStart = Date()
        self.startTime = meetingStart
        self.state = .starting
        
        // Start Timer immediately on MainActor
        startElapsedTimer(from: meetingStart)
        
        do {
            // 1. Request/Verify Permissions only when needed
            let micGranted = await PermissionManager.shared.requestMicrophonePermission()
            guard micGranted else {
                stopElapsedTimer()
                self.state = .failed(.permissionDenied("Microphone permission was denied. Please grant access in macOS System Settings."))
                return
            }
            
            let speechGranted = await PermissionManager.shared.requestSpeechRecognitionPermission()
            guard speechGranted else {
                stopElapsedTimer()
                self.state = .failed(.permissionDenied("Speech Recognition permission was denied. Please enable in macOS System Settings."))
                return
            }
            
            // Check system audio permissions silently without popping modal dialogs
            PermissionManager.shared.checkSystemAudioPermission()
            
            // 2. Start Audio Capture and Recording
            self.state = .capturing
            let (levelStream, bufferStream) = try await audioManager.startCapture(meetingID: self.meetingID)
            
            // Ingest Audio Levels
            levelTask = Task { [weak self] in
                for await level in levelStream {
                    guard let self = self else { break }
                    self.audioLevel = level
                }
            }
            
            // 3. Start Streaming Transcription
            self.state = .transcribing
            let uiTranscriptStream = try await transcriber.start(meetingID: self.meetingID)
            
            // Pipe Audio Buffers to Transcriber
            bufferTask = Task { [weak self] in
                for await buffer in bufferStream {
                    guard let self = self else { break }
                    await self.transcriber.sendAudio(buffer)
                }
            }
            
            // Ingest Live Transcript Updates
            transcriptTask = Task { [weak self] in
                for await segments in uiTranscriptStream {
                    guard let self = self else { break }
                    self.liveSegments = segments
                }
            }
            
            AppLog.general.info("Live meeting session started: \(self.meetingID)")
        } catch {
            stopElapsedTimer()
            self.state = .failed(.audioUnavailable(error.localizedDescription))
            AppLog.audio.error("Failed to start meeting: \(error.localizedDescription)")
        }
    }
    
    public func stopMeeting() async -> Meeting? {
        guard state.isLive else { return nil }
        self.state = .stopping
        
        // 1. Halt capture, timer, & transcriber
        stopElapsedTimer()
        levelTask?.cancel()
        bufferTask?.cancel()
        transcriptTask?.cancel()
        
        let recordedAudioURL = await audioManager.stopCapture()
        let finalSegments = await transcriber.stop()
        self.liveSegments = finalSegments
        self.audioLevel = .zero
        
        // 2. Run On-Device AI Synthesis
        self.state = .processing
        var generatedSummary: MeetingSummary? = nil
        do {
            generatedSummary = try await aiService.synthesizeMeeting(
                meetingID: self.meetingID,
                userNotes: self.userNotes,
                segments: finalSegments,
                recipe: self.selectedRecipe
            )
        } catch {
            AppLog.ai.error("AI synthesis failed: \(error.localizedDescription)")
        }
        
        // 3. Save Meeting to local repository with recorded audio URL
        let meeting = Meeting(
            id: self.meetingID,
            title: self.meetingTitle,
            startDate: self.startTime ?? Date(),
            endDate: Date(),
            duration: self.durationElapsed,
            participants: extractSpeakers(from: finalSegments),
            recipeID: self.selectedRecipe.id,
            userNotes: self.userNotes,
            segments: finalSegments,
            summary: generatedSummary,
            isStarred: false,
            audioFileURL: recordedAudioURL
        )
        
        do {
            try await repository.save(meeting)
            self.state = .completed
            AppLog.general.info("Meeting saved successfully: \(meeting.id)")
            return meeting
        } catch {
            self.state = .failed(.aiProcessingFailed("Could not save meeting: \(error.localizedDescription)"))
            return nil
        }
    }
    
    private func startElapsedTimer(from start: Date) {
        stopElapsedTimer()
        timerTask = Task { @MainActor [weak self] in
            while true {
                try? await Task.sleep(nanoseconds: 250_000_000) // update every 0.25s
                guard let self = self, !Task.isCancelled, self.state.isLive else { break }
                self.durationElapsed = Date().timeIntervalSince(start)
            }
        }
    }
    
    private func stopElapsedTimer() {
        timerTask?.cancel()
        timerTask = nil
    }
    
    private func extractSpeakers(from segments: [TranscriptSegment]) -> [String] {
        let set = Set(segments.map { $0.speaker })
        return set.isEmpty ? ["You"] : Array(set).sorted()
    }
}
