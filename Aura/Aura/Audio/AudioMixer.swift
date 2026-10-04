//
//  AudioMixer.swift
//  Granola
//

import Foundation
import AVFoundation

public final class AudioMixer: @unchecked Sendable {
    private var micGain: Float = 1.0
    private var systemGain: Float = 1.0
    
    public var onMixedBuffer: (@Sendable (AVAudioPCMBuffer) -> Void)?
    
    public init(micGain: Float = 1.0, systemGain: Float = 1.0) {
        self.micGain = micGain
        self.systemGain = systemGain
    }
    
    public func processMicrophoneBuffer(_ buffer: AVAudioPCMBuffer) {
        applyGain(to: buffer, gain: micGain)
        onMixedBuffer?(buffer)
    }
    
    public func processSystemBuffer(_ buffer: AVAudioPCMBuffer) {
        applyGain(to: buffer, gain: systemGain)
        onMixedBuffer?(buffer)
    }
    
    private func applyGain(to buffer: AVAudioPCMBuffer, gain: Float) {
        guard gain != 1.0, let channelData = buffer.floatChannelData else { return }
        let channel = channelData[0]
        let frameCount = Int(buffer.frameLength)
        for i in 0..<frameCount {
            channel[i] = max(-1.0, min(1.0, channel[i] * gain))
        }
    }
}
