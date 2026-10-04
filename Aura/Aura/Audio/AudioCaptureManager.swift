//
//  AudioCaptureManager.swift
//  Granola
//

import Foundation
import AVFoundation
import OSLog

public actor AudioCaptureManager {
    private let micCapture = MicrophoneCapture()
    private let systemCapture = SystemAudioCapture()
    private let mixer = AudioMixer()
    private let recorder = AudioRecorder()
    
    private var isCapturing: Bool = false
    private var levelContinuation: AsyncStream<AudioLevel>.Continuation?
    private var bufferContinuation: AsyncStream<AVAudioPCMBuffer>.Continuation?
    
    private var currentMicLevel: Float = 0.0
    private var currentSystemLevel: Float = 0.0
    private var lastLevelEmit: Date = Date()
    private var recordedAudioURL: URL?
    
    public init() {
        setupBindings()
    }
    
    private func setupBindings() {
        micCapture.onAudioBuffer = { [weak self] buffer in
            Task { [weak self] in
                await self?.handleMicBuffer(buffer)
            }
        }
        
        micCapture.onLevelUpdate = { [weak self] level in
            Task { [weak self] in
                await self?.handleMicLevel(level)
            }
        }
        
        systemCapture.onAudioBuffer = { [weak self] buffer in
            Task { [weak self] in
                await self?.handleSystemBuffer(buffer)
            }
        }
        
        systemCapture.onLevelUpdate = { [weak self] level in
            Task { [weak self] in
                await self?.handleSystemLevel(level)
            }
        }
        
        mixer.onMixedBuffer = { [weak self] buffer in
            Task { [weak self] in
                await self?.handleMixedBuffer(buffer)
            }
        }
    }
    
    public func startCapture(meetingID: UUID) async throws -> (AsyncStream<AudioLevel>, AsyncStream<AVAudioPCMBuffer>) {
        guard !isCapturing else {
            throw AudioCaptureError.engineStartFailed("Capture is already active")
        }
        
        let (levelStream, levelCont) = AsyncStream.makeStream(of: AudioLevel.self)
        self.levelContinuation = levelCont
        
        let (bufferStream, bufferCont) = AsyncStream.makeStream(of: AVAudioPCMBuffer.self)
        self.bufferContinuation = bufferCont
        
        // Start local audio recording
        do {
            self.recordedAudioURL = try recorder.startRecording(meetingID: meetingID)
        } catch {
            AppLog.audio.warning("Could not initialize local audio recorder: \(error.localizedDescription)")
        }
        
        // 1. Start microphone capture
        do {
            try micCapture.start()
        } catch {
            AppLog.audio.error("Failed to start microphone: \(error.localizedDescription)")
            throw error
        }
        
        // 2. Attempt system audio capture (graceful fallback if user has not granted screen recording)
        do {
            try await systemCapture.start()
        } catch {
            AppLog.audio.warning("System audio capture unavailable or not permitted. Continuing with microphone only: \(error.localizedDescription)")
        }
        
        isCapturing = true
        AppLog.audio.info("AudioCaptureManager started capturing successfully.")
        return (levelStream, bufferStream)
    }
    
    public func stopCapture() async -> URL? {
        guard isCapturing else { return recordedAudioURL }
        
        micCapture.stop()
        await systemCapture.stop()
        
        let audioFileURL = recorder.stopRecording()
        
        levelContinuation?.finish()
        levelContinuation = nil
        
        bufferContinuation?.finish()
        bufferContinuation = nil
        
        isCapturing = false
        currentMicLevel = 0.0
        currentSystemLevel = 0.0
        
        AppLog.audio.info("AudioCaptureManager stopped capturing and saved audio to: \(audioFileURL?.path ?? "nil")")
        return audioFileURL
    }
    
    private func handleMicBuffer(_ buffer: AVAudioPCMBuffer) {
        mixer.processMicrophoneBuffer(buffer)
    }
    
    private func handleSystemBuffer(_ buffer: AVAudioPCMBuffer) {
        mixer.processSystemBuffer(buffer)
    }
    
    private func handleMixedBuffer(_ buffer: AVAudioPCMBuffer) {
        recorder.write(buffer: buffer)
        bufferContinuation?.yield(buffer)
    }
    
    private func handleMicLevel(_ level: Float) {
        self.currentMicLevel = level
        emitLevelIfThrottled()
    }
    
    private func handleSystemLevel(_ level: Float) {
        self.currentSystemLevel = level
        emitLevelIfThrottled()
    }
    
    private func emitLevelIfThrottled() {
        let now = Date()
        // Throttle UI level updates to ~30Hz (every 33ms) to keep CPU overhead negligible
        guard now.timeIntervalSince(lastLevelEmit) >= 0.033 else { return }
        lastLevelEmit = now
        
        let audioLevel = AudioLevel(
            micLevel: currentMicLevel,
            systemLevel: currentSystemLevel,
            timestamp: now
        )
        levelContinuation?.yield(audioLevel)
    }
}
