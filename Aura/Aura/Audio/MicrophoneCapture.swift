//
//  MicrophoneCapture.swift
//  Granola
//

import Foundation
import AVFoundation
import OSLog

public final class MicrophoneCapture: @unchecked Sendable {
    private let audioEngine = AVAudioEngine()
    private var isCapturing: Bool = false
    private var converter: AVAudioConverter?
    
    public var onAudioBuffer: (@Sendable (AVAudioPCMBuffer) -> Void)?
    public var onLevelUpdate: (@Sendable (Float) -> Void)?
    
    public init() {}
    
    public func start() throws {
        guard !isCapturing else { return }
        
        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        
        guard inputFormat.sampleRate > 0 else {
            throw AudioCaptureError.deviceUnavailable("Default Microphone has invalid sample rate")
        }
        
        let targetFormat = StandardAudioFormat.processingFormat
        self.converter = AVAudioConverter(from: inputFormat, to: targetFormat)
        
        // Tap input node (buffer size 2048 samples for low latency)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 2048, format: inputFormat) { [weak self] (buffer, time) in
            guard let self = self else { return }
            self.processMicrophoneBuffer(buffer)
        }
        
        do {
            try audioEngine.start()
            isCapturing = true
            AppLog.audio.info("MicrophoneCapture started successfully with input format: \(inputFormat)")
        } catch {
            throw AudioCaptureError.engineStartFailed(error.localizedDescription)
        }
    }
    
    public func stop() {
        guard isCapturing else { return }
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        isCapturing = false
        converter = nil
        AppLog.audio.info("MicrophoneCapture stopped.")
    }
    
    private func processMicrophoneBuffer(_ inputBuffer: AVAudioPCMBuffer) {
        // Calculate RMS Level for lightweight visual amplitude meter
        let level = calculateRMS(buffer: inputBuffer)
        onLevelUpdate?(level)
        
        // Convert to target 16kHz mono format
        guard let converter = self.converter else { return }
        let frameCapacity = AVAudioFrameCount(Double(inputBuffer.frameLength) * (StandardAudioFormat.sampleRate / inputBuffer.format.sampleRate))
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: StandardAudioFormat.processingFormat, frameCapacity: frameCapacity) else { return }
        
        var error: NSError?
        var isConsumed = false
        
        let status = converter.convert(to: outputBuffer, error: &error) { inNumPackets, outStatus in
            if !isConsumed {
                isConsumed = true
                outStatus.pointee = .haveData
                return inputBuffer
            } else {
                outStatus.pointee = .noDataNow
                return nil
            }
        }
        
        if status == .haveData || status == .inputRanDry {
            if outputBuffer.frameLength > 0 {
                onAudioBuffer?(outputBuffer)
            }
        }
    }
    
    private func calculateRMS(buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else { return 0.0 }
        let channelDataPointer = channelData[0]
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return 0.0 }
        
        var sum: Float = 0.0
        for i in 0..<frameLength {
            let sample = channelDataPointer[i]
            sum += sample * sample
        }
        let rms = sqrt(sum / Float(frameLength))
        let db = 20 * log10(max(rms, 0.0001))
        let minDb: Float = -60.0
        let normalized = max(0.0, min(1.0, (db - minDb) / (0.0 - minDb)))
        return normalized
    }
}
