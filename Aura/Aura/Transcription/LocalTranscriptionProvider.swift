//
//  LocalTranscriptionProvider.swift
//  Granola
//

import Foundation
import Speech
import AVFoundation
import OSLog

public final class LocalTranscriptionProvider: TranscriptionProvider, @unchecked Sendable {
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var streamContinuation: AsyncStream<TranscriptSegment>.Continuation?
    
    private var meetingID: UUID?
    private var isRunning: Bool = false
    private var isIntentionalStop: Bool = false
    private var isRestarting: Bool = false
    private var meetingStartTime: Date?
    
    // Continuous Plain Text Accumulation
    private let mainSegmentID = UUID()
    private var accumulatedHistory: String = ""
    private var currentSessionText: String = ""
    private var silenceTimer: Task<Void, Never>?
    private let lock = NSLock()
    
    public init() {
        let currentLocale = Locale.current
        if let recognizer = SFSpeechRecognizer(locale: currentLocale), recognizer.isAvailable {
            self.speechRecognizer = recognizer
        } else {
            self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        }
    }
    
    public func start(meetingID: UUID) async throws -> AsyncStream<TranscriptSegment> {
        self.meetingID = meetingID
        self.isRunning = true
        self.isIntentionalStop = false
        self.isRestarting = false
        self.meetingStartTime = Date()
        self.accumulatedHistory = ""
        self.currentSessionText = ""
        self.silenceTimer?.cancel()
        self.silenceTimer = nil
        
        let authStatus = SFSpeechRecognizer.authorizationStatus()
        if authStatus != .authorized {
            let granted = await PermissionManager.shared.requestSpeechRecognitionPermission()
            guard granted else {
                throw TranscriptionError.authenticationFailed
            }
        }
        
        guard let speechRecognizer = self.speechRecognizer, speechRecognizer.isAvailable else {
            throw TranscriptionError.providerUnavailable
        }
        
        let (stream, continuation) = AsyncStream.makeStream(of: TranscriptSegment.self)
        self.streamContinuation = continuation
        
        try startRecognitionTask()
        
        AppLog.transcription.info("LocalTranscriptionProvider started with live Speech framework.")
        return stream
    }
    
    public func send(audio: AVAudioPCMBuffer) async throws {
        guard isRunning else { return }
        lock.lock()
        let request = self.recognitionRequest
        lock.unlock()
        
        request?.append(audio)
    }
    
    public func stop() async throws {
        silenceTimer?.cancel()
        silenceTimer = nil
        
        lock.lock()
        isRunning = false
        isIntentionalStop = true
        
        // Final commit
        if !currentSessionText.isEmpty {
            if accumulatedHistory.isEmpty {
                accumulatedHistory = currentSessionText
            } else {
                accumulatedHistory += "\n\n" + currentSessionText
            }
            currentSessionText = ""
        }
        
        let finalFullText = accumulatedHistory
        let currentTask = recognitionTask
        let currentRequest = recognitionRequest
        recognitionRequest = nil
        recognitionTask = nil
        let meetingID = self.meetingID ?? UUID()
        let elapsed = Date().timeIntervalSince(self.meetingStartTime ?? Date())
        lock.unlock()
        
        currentRequest?.endAudio()
        currentTask?.cancel()
        
        if !finalFullText.isEmpty {
            let finalSegment = TranscriptSegment(
                id: self.mainSegmentID,
                meetingID: meetingID,
                startTime: 0.0,
                endTime: elapsed,
                speaker: "Transcript",
                text: finalFullText,
                confidence: 0.98,
                isFinal: true
            )
            streamContinuation?.yield(finalSegment)
        }
        
        streamContinuation?.finish()
        streamContinuation = nil
        AppLog.transcription.info("LocalTranscriptionProvider stopped cleanly.")
    }
    
    // MARK: - Internal Recognition Task Management
    
    private func startRecognitionTask() throws {
        guard let speechRecognizer = speechRecognizer else {
            throw TranscriptionError.providerUnavailable
        }
        
        lock.lock()
        recognitionTask?.cancel()
        recognitionTask = nil
        
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.addsPunctuation = true
        
        if speechRecognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }
        
        self.recognitionRequest = request
        self.currentSessionText = ""
        lock.unlock()
        
        let meetingID = self.meetingID ?? UUID()
        
        self.recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] (result, error) in
            guard let self = self else { return }
            
            if let result = result {
                self.processRecognitionResult(result, meetingID: meetingID)
            }
            
            if let error = error {
                self.lock.lock()
                let shouldRestart = !self.isIntentionalStop && !self.isRestarting && self.isRunning
                self.lock.unlock()
                
                if shouldRestart {
                    AppLog.transcription.warning("Speech recognition task event: \(error.localizedDescription). Reconnecting task...")
                    self.commitAndRestartTask()
                }
            } else if result?.isFinal == true {
                self.lock.lock()
                let shouldRestart = !self.isIntentionalStop && !self.isRestarting && self.isRunning
                self.lock.unlock()
                
                if shouldRestart {
                    self.commitAndRestartTask()
                }
            }
        }
    }
    
    private func processRecognitionResult(_ result: SFSpeechRecognitionResult, meetingID: UUID) {
        let liveFormattedString = result.bestTranscription.formattedString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !liveFormattedString.isEmpty else { return }
        
        lock.lock()
        self.currentSessionText = liveFormattedString
        let fullTranscript: String
        if self.accumulatedHistory.isEmpty {
            fullTranscript = liveFormattedString
        } else {
            fullTranscript = self.accumulatedHistory + "\n\n" + liveFormattedString
        }
        let elapsed = Date().timeIntervalSince(self.meetingStartTime ?? Date())
        lock.unlock()
        
        let segment = TranscriptSegment(
            id: self.mainSegmentID,
            meetingID: meetingID,
            startTime: 0.0,
            endTime: elapsed,
            speaker: "Transcript",
            text: fullTranscript,
            confidence: 0.98,
            isFinal: result.isFinal
        )
        
        self.streamContinuation?.yield(segment)
        
        // Reset silence timer: commit phrase to history after 1.2s pause & refresh recognizer for next speech
        resetSilenceTimer()
        
        if result.isFinal {
            commitAndRestartTask()
        }
    }
    
    private func resetSilenceTimer() {
        silenceTimer?.cancel()
        guard isRunning else { return }
        
        silenceTimer = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_200_000_000) // 1.2s pause
            guard let self = self, self.isRunning, !Task.isCancelled else { return }
            self.commitAndRestartTask()
        }
    }
    
    private func commitAndRestartTask() {
        lock.lock()
        guard isRunning, !isRestarting, !isIntentionalStop else {
            lock.unlock()
            return
        }
        
        guard !currentSessionText.isEmpty else {
            lock.unlock()
            return
        }
        
        isRestarting = true
        
        // Commit current phrase
        if accumulatedHistory.isEmpty {
            accumulatedHistory = currentSessionText
        } else {
            accumulatedHistory += "\n\n" + currentSessionText
        }
        currentSessionText = ""
        
        let oldTask = self.recognitionTask
        let oldRequest = self.recognitionRequest
        self.recognitionTask = nil
        self.recognitionRequest = nil
        lock.unlock()
        
        oldRequest?.endAudio()
        oldTask?.cancel()
        
        Task {
            try? await Task.sleep(nanoseconds: 60_000_000)
            self.lock.lock()
            self.isRestarting = false
            let shouldRun = self.isRunning && !self.isIntentionalStop
            self.lock.unlock()
            
            if shouldRun {
                try? self.startRecognitionTask()
            }
        }
    }
}
