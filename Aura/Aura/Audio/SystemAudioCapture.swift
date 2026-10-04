//
//  SystemAudioCapture.swift
//  Granola
//

import Foundation
import ScreenCaptureKit
import AVFoundation
import CoreGraphics
import OSLog

public final class SystemAudioCapture: NSObject, SCStreamOutput, SCStreamDelegate, @unchecked Sendable {
    private var stream: SCStream?
    private var isCapturing: Bool = false
    private var converter: AVAudioConverter?
    
    public var onAudioBuffer: (@Sendable (AVAudioPCMBuffer) -> Void)?
    public var onLevelUpdate: (@Sendable (Float) -> Void)?
    
    public override init() {
        super.init()
    }
    
    public func start() async throws {
        guard !isCapturing else { return }
        
        // Verify permission
        guard CGPreflightScreenCaptureAccess() else {
            throw AudioCaptureError.systemAudioPermissionDenied
        }
        
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            guard let display = content.displays.first else {
                throw AudioCaptureError.screenCaptureKitUnavailable
            }
            
            let filter = SCContentFilter(display: display, excludingWindows: [])
            let config = SCStreamConfiguration()
            config.capturesAudio = true
            config.excludesCurrentProcessAudio = true
            config.sampleRate = 48000
            config.channelCount = 2
            
            // Minimize video overhead since we are capturing audio only
            config.width = 16
            config.height = 16
            config.minimumFrameInterval = CMTime(value: 1, timescale: 1) // 1 fps minimum video
            
            let stream = SCStream(filter: filter, configuration: config, delegate: self)
            try stream.addStreamOutput(self, type: .audio, sampleHandlerQueue: DispatchQueue(label: "com.nilkanth.Granola.systemAudioQueue", qos: .userInitiated))
            
            try await stream.startCapture()
            self.stream = stream
            self.isCapturing = true
            AppLog.audio.info("SystemAudioCapture started successfully via ScreenCaptureKit.")
        } catch {
            AppLog.audio.error("Failed to start ScreenCaptureKit audio stream: \(error.localizedDescription)")
            throw AudioCaptureError.streamConfigurationFailed(error.localizedDescription)
        }
    }
    
    public func stop() async {
        guard isCapturing, let stream = self.stream else { return }
        do {
            try await stream.stopCapture()
            AppLog.audio.info("SystemAudioCapture stopped.")
        } catch {
            AppLog.audio.error("Error stopping ScreenCaptureKit stream: \(error.localizedDescription)")
        }
        self.stream = nil
        self.isCapturing = false
        self.converter = nil
    }
    
    // MARK: - SCStreamOutput
    public func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .audio, sampleBuffer.isValid else { return }
        
        guard let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer),
              let audioStreamBasicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription) else {
            return
        }
        
        let sampleRate = audioStreamBasicDescription.pointee.mSampleRate
        let channels = audioStreamBasicDescription.pointee.mChannelsPerFrame
        
        guard let inputFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: channels,
            interleaved: false
        ) else { return }
        
        if self.converter == nil || self.converter?.inputFormat != inputFormat {
            self.converter = AVAudioConverter(from: inputFormat, to: StandardAudioFormat.processingFormat)
        }
        
        // Extract audio buffer
        var audioBufferList = AudioBufferList()
        var blockBuffer: CMBlockBuffer?
        
        let status = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
            sampleBuffer,
            bufferListSizeNeededOut: nil,
            bufferListOut: &audioBufferList,
            bufferListSize: MemoryLayout<AudioBufferList>.size,
            blockBufferAllocator: nil,
            blockBufferMemoryAllocator: nil,
            flags: 0,
            blockBufferOut: &blockBuffer
        )
        
        guard status == noErr else { return }
        
        let numFrames = CMSampleBufferGetNumSamples(sampleBuffer)
        guard let pcmBuffer = AVAudioPCMBuffer(pcmFormat: inputFormat, frameCapacity: AVAudioFrameCount(numFrames)) else { return }
        pcmBuffer.frameLength = AVAudioFrameCount(numFrames)
        
        // Copy audio data into PCM Buffer
        let buffers = UnsafeMutableAudioBufferListPointer(&audioBufferList)
        for (index, buffer) in buffers.enumerated() {
            if let dest = pcmBuffer.floatChannelData?[index], let src = buffer.mData {
                memcpy(dest, src, Int(buffer.mDataByteSize))
            }
        }
        
        // Measure RMS
        let level = calculateRMS(buffer: pcmBuffer)
        onLevelUpdate?(level)
        
        // Convert to standard 16kHz mono
        guard let converter = self.converter else { return }
        let frameCapacity = AVAudioFrameCount(Double(pcmBuffer.frameLength) * (StandardAudioFormat.sampleRate / pcmBuffer.format.sampleRate))
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: StandardAudioFormat.processingFormat, frameCapacity: frameCapacity) else { return }
        
        var convertError: NSError?
        var isConsumed = false
        
        let convertStatus = converter.convert(to: outputBuffer, error: &convertError) { inNumPackets, outStatus in
            if !isConsumed {
                isConsumed = true
                outStatus.pointee = .haveData
                return pcmBuffer
            } else {
                outStatus.pointee = .noDataNow
                return nil
            }
        }
        
        if convertStatus == .haveData || convertStatus == .inputRanDry {
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
