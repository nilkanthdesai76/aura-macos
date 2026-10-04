//
//  TranscriptionProvider.swift
//  Granola
//

import Foundation
import AVFoundation

public enum TranscriptionError: LocalizedError, Sendable {
    case connectionFailed(String)
    case authenticationFailed
    case providerUnavailable
    case invalidResponse(String)
    case streamClosed
    
    public var errorDescription: String? {
        switch self {
        case .connectionFailed(let reason):
            return "Transcription connection failed: \(reason)"
        case .authenticationFailed:
            return "Authentication failed for transcription provider. Check your API key in Settings."
        case .providerUnavailable:
            return "Transcription service is currently unavailable."
        case .invalidResponse(let message):
            return "Received invalid response from speech service: \(message)"
        case .streamClosed:
            return "Transcription stream was closed unexpectedly."
        }
    }
}

public protocol TranscriptionProvider: Sendable {
    func start(meetingID: UUID) async throws -> AsyncStream<TranscriptSegment>
    func send(audio: AVAudioPCMBuffer) async throws
    func stop() async throws
}
