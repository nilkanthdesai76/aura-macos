//
//  AudioModels.swift
//  Granola
//

import Foundation
import AVFoundation

public struct AudioLevel: Sendable, Equatable {
    public let micLevel: Float      // 0.0 to 1.0
    public let systemLevel: Float   // 0.0 to 1.0
    public let timestamp: Date
    
    public init(micLevel: Float = 0.0, systemLevel: Float = 0.0, timestamp: Date = Date()) {
        self.micLevel = max(0.0, min(1.0, micLevel))
        self.systemLevel = max(0.0, min(1.0, systemLevel))
        self.timestamp = timestamp
    }
    
    public static let zero = AudioLevel(micLevel: 0, systemLevel: 0)
}

public enum AudioCaptureError: LocalizedError, Sendable {
    case microphonePermissionDenied
    case systemAudioPermissionDenied
    case deviceUnavailable(String)
    case engineStartFailed(String)
    case screenCaptureKitUnavailable
    case streamConfigurationFailed(String)
    case conversionFailed
    
    public var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            return "Microphone access is denied. Please enable Microphone in System Settings."
        case .systemAudioPermissionDenied:
            return "Screen & System Audio recording permission is required to capture meeting audio."
        case .deviceUnavailable(let name):
            return "Audio device '\(name)' is unavailable."
        case .engineStartFailed(let reason):
            return "Failed to start audio engine: \(reason)"
        case .screenCaptureKitUnavailable:
            return "ScreenCaptureKit audio tap is unavailable on this device."
        case .streamConfigurationFailed(let reason):
            return "Failed to configure audio capture stream: \(reason)"
        case .conversionFailed:
            return "Audio format conversion failed."
        }
    }
}

public enum StandardAudioFormat {
    /// Standard 16kHz, 1-channel (Mono), 32-bit float or 16-bit linear PCM format used across speech engines
    public static let sampleRate: Double = 16000.0
    public static let channelCount: AVAudioChannelCount = 1
    
    public static let processingFormat: AVAudioFormat = {
        guard let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: channelCount,
            interleaved: false
        ) else {
            fatalError("Failed to create standard 16kHz mono audio format")
        }
        return format
    }()
}
