//
//  StreamingTranscriber.swift
//  Granola
//

import Foundation
import AVFoundation
import OSLog

public actor StreamingTranscriber {
    private var provider: TranscriptionProvider
    private var segments: [TranscriptSegment] = []
    private var isStreaming: Bool = false
    private var streamTask: Task<Void, Never>?
    private var transcriptContinuation: AsyncStream<[TranscriptSegment]>.Continuation?
    
    public init(provider: TranscriptionProvider = LocalTranscriptionProvider()) {
        self.provider = provider
    }
    
    public func setProvider(_ provider: TranscriptionProvider) {
        self.provider = provider
    }
    
    public func start(meetingID: UUID) async throws -> AsyncStream<[TranscriptSegment]> {
        guard !isStreaming else { return AsyncStream { $0.finish() } }
        
        segments.removeAll()
        isStreaming = true
        
        let (uiStream, uiContinuation) = AsyncStream.makeStream(of: [TranscriptSegment].self)
        self.transcriptContinuation = uiContinuation
        
        let segmentStream = try await provider.start(meetingID: meetingID)
        
        streamTask = Task { [weak self] in
            for await segment in segmentStream {
                guard let self = self else { break }
                await self.handleIncomingSegment(segment)
            }
        }
        
        AppLog.transcription.info("StreamingTranscriber started.")
        return uiStream
    }
    
    public func sendAudio(_ buffer: AVAudioPCMBuffer) async {
        guard isStreaming else { return }
        do {
            try await provider.send(audio: buffer)
        } catch {
            AppLog.transcription.error("Error sending audio to transcriber: \(error.localizedDescription)")
        }
    }
    
    public func stop() async -> [TranscriptSegment] {
        guard isStreaming else { return segments }
        
        streamTask?.cancel()
        streamTask = nil
        
        do {
            try await provider.stop()
        } catch {
            AppLog.transcription.error("Error stopping transcriber: \(error.localizedDescription)")
        }
        
        transcriptContinuation?.finish()
        transcriptContinuation = nil
        
        isStreaming = false
        AppLog.transcription.info("StreamingTranscriber stopped with \(self.segments.count) segments.")
        return segments
    }
    
    public func getAllSegments() -> [TranscriptSegment] {
        return segments
    }
    
    private func handleIncomingSegment(_ segment: TranscriptSegment) {
        if let existingIndex = segments.firstIndex(where: { $0.id == segment.id }) {
            // Update interim or final segment in-place
            segments[existingIndex] = segment
        } else {
            // Append new segment
            segments.append(segment)
        }
        
        transcriptContinuation?.yield(segments)
    }
}
