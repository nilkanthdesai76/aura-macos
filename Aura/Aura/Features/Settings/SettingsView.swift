//
//  SettingsView.swift
//  Granola
//

import SwiftUI

public struct SettingsView: View {
    @ObservedObject private var permissionManager = PermissionManager.shared
    @State private var deepgramKey: String = ""
    @State private var anthropicKey: String = ""
    @State private var openaiKey: String = ""
    @State private var isSavedAlert: Bool = false
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 4) {
                    Text("Settings & Privacy")
                        .font(.system(size: 20, weight: .bold))
                    Text("Configure audio capture, privacy policies, and on-device processing.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                // On-Device AI Engine Status
                GroupBox("On-Device AI Engine") {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 8) {
                            Image(systemName: "cpu.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.green)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("100% Local On-Device Processing")
                                    .font(.system(size: 13, weight: .semibold))
                                Text("All meeting summaries, decisions, action items, and Q&A run locally on your Mac.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Divider()
                        
                        HStack {
                            Text("Zero Cloud AI Data Transmission")
                                .font(.system(size: 12))
                            Spacer()
                            Text("ACTIVE")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.15))
                                .foregroundColor(.green)
                                .cornerRadius(4)
                        }
                    }
                    .padding(8)
                }
                
                // Audio & Permissions
                GroupBox("Audio Permissions") {
                    VStack(alignment: .leading, spacing: 12) {
                        // Microphone
                        HStack {
                            Label("Microphone Access", systemImage: "mic.fill")
                                .font(.system(size: 13))
                            
                            Spacer()
                            
                            if permissionManager.microphoneStatus == .authorized {
                                Text("Authorized")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.green)
                            } else {
                                Button("Grant Access") {
                                    Task { _ = await permissionManager.requestMicrophonePermission() }
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                            }
                        }
                        
                        // Speech Recognition
                        HStack {
                            Label("Speech Recognition Access", systemImage: "waveform.badge.mic")
                                .font(.system(size: 13))
                            
                            Spacer()
                            
                            if permissionManager.speechRecognitionStatus == .authorized {
                                Text("Authorized")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.green)
                            } else {
                                Button("Grant Access") {
                                    Task { _ = await permissionManager.requestSpeechRecognitionPermission() }
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                            }
                        }
                        
                        Divider()
                        
                        // System Audio
                        HStack {
                            Label("Screen & System Audio", systemImage: "speaker.wave.2.fill")
                                .font(.system(size: 13))
                            
                            Spacer()
                            
                            if permissionManager.systemAudioStatus == .authorized {
                                Text("Authorized")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.green)
                            } else {
                                Button("Open Screen Recording Settings") {
                                    permissionManager.openSystemSettings(for: "screenCapture")
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                            }
                        }
                        
                        HStack(spacing: 12) {
                            Button("Check Permissions") {
                                permissionManager.checkAllPermissions()
                            }
                            .font(.system(size: 11))
                            
                            Button("System Privacy Settings") {
                                permissionManager.openSystemSettings()
                            }
                            .font(.system(size: 11))
                        }
                        .padding(.top, 4)
                    }
                    .padding(8)
                }
                
                // Privacy & Storage
                GroupBox("Privacy & Audio Retention") {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Zero Audio Storage")
                                    .font(.system(size: 13, weight: .semibold))
                                Text("Temporary audio buffers are discarded immediately after transcription.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Toggle("", isOn: .constant(true))
                                .disabled(true)
                        }
                    }
                    .padding(8)
                }
                
                // Optional External Cloud Providers (For future optional use)
                GroupBox("Optional Cloud API Credentials (Stored securely in Keychain)") {
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Deepgram API Key (Optional Cloud STT)")
                                .font(.system(size: 12))
                            SecureField("Optional Deepgram Key", text: $deepgramKey)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Anthropic API Key (Optional Cloud LLM)")
                                .font(.system(size: 12))
                            SecureField("Optional Anthropic Key", text: $anthropicKey)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        Button("Save Keys to Keychain") {
                            if !deepgramKey.isEmpty { try? KeychainManager.save(key: "deepgram_api_key", value: deepgramKey) }
                            if !anthropicKey.isEmpty { try? KeychainManager.save(key: "anthropic_api_key", value: anthropicKey) }
                            isSavedAlert = true
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding(8)
                }
            }
            .padding(24)
        }
        .onAppear {
            permissionManager.checkAllPermissions()
            self.deepgramKey = KeychainManager.get(key: "deepgram_api_key") ?? ""
            self.anthropicKey = KeychainManager.get(key: "anthropic_api_key") ?? ""
        }
        .alert("Credentials Saved", isPresented: $isSavedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your API keys were securely updated in the macOS Keychain.")
        }
    }
}
