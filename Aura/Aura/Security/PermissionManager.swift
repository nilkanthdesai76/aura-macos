//
//  PermissionManager.swift
//  Granola
//

import Foundation
import AVFoundation
import Speech
import CoreGraphics
import AppKit
import Combine
import OSLog

public enum PermissionStatus: Sendable {
    case notDetermined
    case authorized
    case denied
    case restricted
}

@MainActor
public final class PermissionManager: ObservableObject {
    public static let shared = PermissionManager()
    
    @Published public private(set) var microphoneStatus: PermissionStatus = .notDetermined
    @Published public private(set) var speechRecognitionStatus: PermissionStatus = .notDetermined
    @Published public private(set) var systemAudioStatus: PermissionStatus = .notDetermined
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        checkAllPermissions()
        setupFocusObserver()
    }
    
    private func setupFocusObserver() {
        NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.checkAllPermissions()
            }
            .store(in: &cancellables)
    }
    
    public func checkAllPermissions() {
        checkMicrophonePermission()
        checkSpeechRecognitionPermission()
        checkSystemAudioPermission()
    }
    
    public func checkMicrophonePermission() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            microphoneStatus = .authorized
        case .denied:
            microphoneStatus = .denied
        case .restricted:
            microphoneStatus = .restricted
        case .notDetermined:
            microphoneStatus = .notDetermined
        @unknown default:
            microphoneStatus = .notDetermined
        }
    }
    
    public func requestMicrophonePermission() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            microphoneStatus = .authorized
            return true
        case .denied, .restricted:
            microphoneStatus = .denied
            return false
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .audio)
            checkMicrophonePermission()
            return granted
        @unknown default:
            return false
        }
    }
    
    public func checkSpeechRecognitionPermission() {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            speechRecognitionStatus = .authorized
        case .denied:
            speechRecognitionStatus = .denied
        case .restricted:
            speechRecognitionStatus = .restricted
        case .notDetermined:
            speechRecognitionStatus = .notDetermined
        @unknown default:
            speechRecognitionStatus = .notDetermined
        }
    }
    
    private var isRequestingSpeech: Bool = false
    
    public func requestSpeechRecognitionPermission() async -> Bool {
        let status = SFSpeechRecognizer.authorizationStatus()
        if status == .authorized {
            speechRecognitionStatus = .authorized
            return true
        } else if status == .denied || status == .restricted {
            speechRecognitionStatus = .denied
            return false
        }
        
        guard !isRequestingSpeech else {
            return speechRecognitionStatus == .authorized
        }
        isRequestingSpeech = true
        defer { isRequestingSpeech = false }
        
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { [weak self] auth in
                Task { @MainActor in
                    self?.checkSpeechRecognitionPermission()
                    continuation.resume(returning: auth == .authorized)
                }
            }
        }
    }
    
    public func checkSystemAudioPermission() {
        if CGPreflightScreenCaptureAccess() {
            systemAudioStatus = .authorized
        } else {
            systemAudioStatus = .denied
        }
    }
    
    public func requestSystemAudioPermission() -> Bool {
        if CGPreflightScreenCaptureAccess() {
            systemAudioStatus = .authorized
            return true
        }
        let granted = CGRequestScreenCaptureAccess()
        checkSystemAudioPermission()
        return granted
    }
    
    public func openSystemSettings(for type: String = "privacy") {
        let path: String
        switch type {
        case "screenCapture":
            path = "Privacy_ScreenCapture"
        case "speech":
            path = "Privacy_SpeechRecognition"
        default:
            path = "Privacy_Microphone"
        }
        
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(path)") {
            NSWorkspace.shared.open(url)
        }
    }
}
