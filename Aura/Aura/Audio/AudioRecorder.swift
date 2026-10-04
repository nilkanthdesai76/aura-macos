//
//  AudioRecorder.swift
//  Granola
//

import Foundation
import AVFoundation
import OSLog

public final class AudioRecorder: @unchecked Sendable {
    private var audioFile: AVAudioFile?
    private var outputURL: URL?
    private var isRecording: Bool = false
    private let lock = NSLock()
    
    public init() {}
    
    public static func recordingsDirectory() -> URL {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? fileManager.temporaryDirectory
        let recordingsDir = appSupport.appendingPathComponent("com.nilkanth.Granola/Recordings", isDirectory: true)
        try? fileManager.createDirectory(at: recordingsDir, withIntermediateDirectories: true)
        return recordingsDir
    }
    
    public func startRecording(meetingID: UUID) throws -> URL {
        lock.lock()
        defer { lock.unlock() }
        
        let dir = Self.recordingsDirectory()
        let fileURL = dir.appendingPathComponent("\(meetingID.uuidString).wav")
        
        // Remove existing file if present
        try? FileManager.default.removeItem(at: fileURL)
        
        let settings = StandardAudioFormat.processingFormat.settings
        
        do {
            let file = try AVAudioFile(forWriting: fileURL, settings: settings, commonFormat: .pcmFormatFloat32, interleaved: false)
            self.audioFile = file
            self.outputURL = fileURL
            self.isRecording = true
            AppLog.audio.info("AudioRecorder started recording to: \(fileURL.path)")
            return fileURL
        } catch {
            AppLog.audio.error("Failed to create AVAudioFile for recording: \(error.localizedDescription)")
            throw error
        }
    }
    
    public func write(buffer: AVAudioPCMBuffer) {
        lock.lock()
        defer { lock.unlock() }
        guard isRecording, let file = audioFile else { return }
        
        do {
            try file.write(from: buffer)
        } catch {
            AppLog.audio.error("Error writing buffer to audio file: \(error.localizedDescription)")
        }
    }
    
    public func stopRecording() -> URL? {
        lock.lock()
        defer { lock.unlock() }
        guard isRecording else { return outputURL }
        
        isRecording = false
        audioFile = nil
        let finalURL = outputURL
        AppLog.audio.info("AudioRecorder stopped. Output file: \(finalURL?.path ?? "nil")")
        return finalURL
    }
}
