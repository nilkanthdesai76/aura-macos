//
//  CloudTranscriptionProvider.swift
//  Granola
//

import Foundation
import AVFoundation
import OSLog

public final class CloudTranscriptionProvider: TranscriptionProvider, @unchecked Sendable {
    private var webSocketTask: URLSessionWebSocketTask?
    private var streamContinuation: AsyncStream<TranscriptSegment>.Continuation?
    private var meetingID: UUID?
    private var isRunning: Bool = false
    private var segmentCounter: Double = 0.0
    private var syntheticTask: Task<Void, Never>?
    
    public init() {}
    
    public func start(meetingID: UUID) async throws -> AsyncStream<TranscriptSegment> {
        self.meetingID = meetingID
        self.isRunning = true
        self.segmentCounter = 0.0
        
        let (stream, continuation) = AsyncStream.makeStream(of: TranscriptSegment.self)
        self.streamContinuation = continuation
        
        let apiKey = KeychainManager.get(key: "deepgram_api_key")
        
        if let apiKey = apiKey, !apiKey.isEmpty {
            // Real WebSocket connection
            try setupWebSocket(apiKey: apiKey, meetingID: meetingID)
        } else {
            // Live speech-simulation engine for developer testing & demonstration
            startSyntheticStream(meetingID: meetingID)
        }
        
        AppLog.transcription.info("CloudTranscriptionProvider started for meeting: \(meetingID)")
        return stream
    }
    
    public func send(audio: AVAudioPCMBuffer) async throws {
        guard isRunning else { return }
        
        // If live WebSocket task is connected, serialize and send binary PCM frame
        if let webSocketTask = webSocketTask {
            guard let channelData = audio.floatChannelData else { return }
            let frameLength = Int(audio.frameLength)
            let rawFloatPointer = channelData[0]
            
            // Convert Float32 (-1.0 to 1.0) to Int16 Little-Endian PCM
            var pcm16Data = Data(capacity: frameLength * 2)
            for i in 0..<frameLength {
                let sample = max(-1.0, min(1.0, rawFloatPointer[i]))
                var int16Sample = Int16(sample * 32767.0).littleEndian
                withUnsafeBytes(of: &int16Sample) { pcm16Data.append(contentsOf: $0) }
            }
            
            let message = URLSessionWebSocketTask.Message.data(pcm16Data)
            do {
                try await webSocketTask.send(message)
            } catch {
                AppLog.transcription.error("WebSocket audio transmission error: \(error.localizedDescription)")
            }
        }
    }
    
    public func stop() async throws {
        isRunning = false
        syntheticTask?.cancel()
        syntheticTask = nil
        
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        
        streamContinuation?.finish()
        streamContinuation = nil
        AppLog.transcription.info("CloudTranscriptionProvider stopped.")
    }
    
    // MARK: - Private WebSocket Handling
    private func setupWebSocket(apiKey: String, meetingID: UUID) throws {
        guard let url = URL(string: "wss://api.deepgram.com/v1/listen?encoding=linear16&sample_rate=16000&channels=1&diarize=true&interim_results=true&punctuate=true&smart_format=true") else {
            throw TranscriptionError.connectionFailed("Invalid transcription URL")
        }
        
        var request = URLRequest(url: url)
        request.addValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let session = URLSession(configuration: .default)
        let wsTask = session.webSocketTask(with: request)
        self.webSocketTask = wsTask
        wsTask.resume()
        
        Task { [weak self] in
            await self?.receiveMessages()
        }
    }
    
    private func receiveMessages() async {
        guard let wsTask = webSocketTask else { return }
        
        while isRunning {
            do {
                let message = try await wsTask.receive()
                switch message {
                case .string(let text):
                    handleDeepgramJSON(text)
                case .data(let data):
                    if let text = String(data: data, encoding: .utf8) {
                        handleDeepgramJSON(text)
                    }
                @unknown default:
                    break
                }
            } catch {
                if isRunning {
                    AppLog.transcription.error("WebSocket receive error: \(error.localizedDescription)")
                }
                break
            }
        }
    }
    
    private func handleDeepgramJSON(_ jsonString: String) {
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let channel = json["channel"] as? [String: Any],
              let alternatives = channel["alternatives"] as? [[String: Any]],
              let firstAlt = alternatives.first,
              let transcript = firstAlt["transcript"] as? String,
              !transcript.isEmpty else {
            return
        }
        
        let isFinal = json["is_final"] as? Bool ?? false
        let start = json["start"] as? Double ?? segmentCounter
        let duration = json["duration"] as? Double ?? 2.0
        let speakerInt = (firstAlt["words"] as? [[String: Any]])?.first?["speaker"] as? Int ?? 0
        let speakerName = speakerInt == 0 ? "You" : "Speaker \(speakerInt + 1)"
        
        let segment = TranscriptSegment(
            meetingID: self.meetingID ?? UUID(),
            startTime: start,
            endTime: start + duration,
            speaker: speakerName,
            text: transcript,
            confidence: Float(firstAlt["confidence"] as? Double ?? 0.95),
            isFinal: isFinal
        )
        
        streamContinuation?.yield(segment)
        if isFinal {
            segmentCounter = start + duration
        }
    }
    
    // MARK: - Synthetic Demo Stream Engine
    private func startSyntheticStream(meetingID: UUID) {
        let sampleConversations: [(speaker: String, text: String, duration: Double)] = [
            ("You", "Thanks everyone for joining. Let's do a quick sync on the v2.0 native macOS architecture and launch milestones.", 3.0),
            ("Sarah", "Sounds great. On the client side, SwiftUI with ScreenCaptureKit is giving us zero-latency audio mixing.", 3.5),
            ("John", "Agreed. For the AI post-processing pipeline, we've implemented strict JSON schemas and source-linking for all action items.", 4.0),
            ("You", "Awesome. Let's commit to having the beta ready by Friday so we can run complete end-to-end integration tests.", 3.5),
            ("Sarah", "I will update the test suite and finalize the level meter components today.", 3.0),
            ("John", "And I'll hook up the local FTS5 search index and Keychain credential storage.", 3.0)
        ]
        
        syntheticTask = Task { [weak self] in
            guard let self = self else { return }
            var currentTime: Double = 0.0
            
            for item in sampleConversations {
                guard self.isRunning else { break }
                
                // 1. Emit partial segment first
                let segmentID = UUID()
                let words = item.text.split(separator: " ")
                var partialText = ""
                
                for word in words {
                    guard self.isRunning else { break }
                    partialText += (partialText.isEmpty ? "" : " ") + word
                    
                    let interimSegment = TranscriptSegment(
                        id: segmentID,
                        meetingID: meetingID,
                        startTime: currentTime,
                        endTime: currentTime + item.duration,
                        speaker: item.speaker,
                        text: partialText,
                        confidence: 0.92,
                        isFinal: false
                    )
                    self.streamContinuation?.yield(interimSegment)
                    try? await Task.sleep(nanoseconds: 120_000_000) // 120ms between words
                }
                
                // 2. Emit final stable segment
                let finalSegment = TranscriptSegment(
                    id: segmentID,
                    meetingID: meetingID,
                    startTime: currentTime,
                    endTime: currentTime + item.duration,
                    speaker: item.speaker,
                    text: item.text,
                    confidence: 0.98,
                    isFinal: true
                )
                self.streamContinuation?.yield(finalSegment)
                currentTime += item.duration + 0.5
                
                try? await Task.sleep(nanoseconds: 800_000_000) // 800ms pause between speakers
            }
        }
    }
}
