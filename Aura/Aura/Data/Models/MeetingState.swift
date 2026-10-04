//
//  MeetingState.swift
//  Granola
//

import Foundation

public enum MeetingError: LocalizedError, Equatable, Sendable {
    case permissionDenied(String)
    case audioUnavailable(String)
    case transcriptionFailed(String)
    case aiProcessingFailed(String)
    case networkUnavailable
    case cancelled
    
    public var errorDescription: String? {
        switch self {
        case .permissionDenied(let detail):
            return "Permission required: \(detail)"
        case .audioUnavailable(let detail):
            return "Audio device error: \(detail)"
        case .transcriptionFailed(let detail):
            return "Transcription error: \(detail)"
        case .aiProcessingFailed(let detail):
            return "AI synthesis error: \(detail)"
        case .networkUnavailable:
            return "Network connection unavailable."
        case .cancelled:
            return "The meeting session was cancelled."
        }
    }
}

public enum MeetingState: Equatable, Sendable {
    case idle
    case starting
    case capturing
    case transcribing
    case stopping
    case processing
    case completed
    case failed(MeetingError)
    
    public var isLive: Bool {
        switch self {
        case .starting, .capturing, .transcribing:
            return true
        default:
            return false
        }
    }
    
    public var titleDescription: String {
        switch self {
        case .idle:
            return "Ready"
        case .starting:
            return "Initializing audio..."
        case .capturing:
            return "Capturing audio..."
        case .transcribing:
            return "Transcribing live..."
        case .stopping:
            return "Stopping meeting..."
        case .processing:
            return "AI synthesizing notes..."
        case .completed:
            return "Completed"
        case .failed(let error):
            return "Error: \(error.localizedDescription)"
        }
    }
}
