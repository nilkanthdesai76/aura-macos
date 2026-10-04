//
//  AudioPlayerView.swift
//  Granola
//

import SwiftUI
import AVFoundation
import Combine

@MainActor
public final class AudioPlayerController: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published public var isPlaying: Bool = false
    @Published public var currentTime: TimeInterval = 0.0
    @Published public var duration: TimeInterval = 0.0
    @Published public var playbackRate: Float = 1.0
    
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    
    public func loadAudio(url: URL) {
        stop()
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.delegate = self
            player.enableRate = true
            player.prepareToPlay()
            self.audioPlayer = player
            self.duration = player.duration
            self.currentTime = 0.0
            self.isPlaying = false
        } catch {
            print("Failed to load audio file: \(error.localizedDescription)")
        }
    }
    
    public func togglePlayPause() {
        guard let player = audioPlayer else { return }
        if player.isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    public func play() {
        guard let player = audioPlayer else { return }
        player.rate = playbackRate
        player.play()
        isPlaying = true
        startTimer()
    }
    
    public func pause() {
        audioPlayer?.pause()
        isPlaying = false
        stopTimer()
    }
    
    public func stop() {
        audioPlayer?.stop()
        isPlaying = false
        stopTimer()
        currentTime = 0.0
    }
    
    public func seek(to time: TimeInterval) {
        guard let player = audioPlayer else { return }
        let clamped = max(0, min(time, duration))
        player.currentTime = clamped
        currentTime = clamped
        if !isPlaying {
            play()
        }
    }
    
    public func skipForward(seconds: Double = 10.0) {
        seek(to: currentTime + seconds)
    }
    
    public func skipBackward(seconds: Double = 10.0) {
        seek(to: currentTime - seconds)
    }
    
    public func setRate(_ rate: Float) {
        self.playbackRate = rate
        if let player = audioPlayer, player.isPlaying {
            player.rate = rate
        }
    }
    
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, let player = self.audioPlayer else { return }
                self.currentTime = player.currentTime
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    public nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isPlaying = false
            self.currentTime = self.duration
            self.stopTimer()
        }
    }
}

public struct AudioPlayerView: View {
    @ObservedObject public var controller: AudioPlayerController
    public let audioURL: URL?
    
    public init(controller: AudioPlayerController, audioURL: URL?) {
        self.controller = controller
        self.audioURL = audioURL
    }
    
    public var body: some View {
        HStack(spacing: 14) {
            // Play / Pause Button
            Button {
                controller.togglePlayPause()
            } label: {
                Image(systemName: controller.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)
            
            // Skip Buttons
            Button {
                controller.skipBackward(seconds: 10)
            } label: {
                Image(systemName: "gobackward.10")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            
            Button {
                controller.skipForward(seconds: 10)
            } label: {
                Image(systemName: "goforward.10")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            
            // Time Labels & Scrubber
            HStack(spacing: 8) {
                Text(formatTime(controller.currentTime))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(width: 40, alignment: .trailing)
                
                Slider(
                    value: Binding(
                        get: { controller.currentTime },
                        set: { controller.seek(to: $0) }
                    ),
                    in: 0...max(1.0, controller.duration)
                )
                .controlSize(.small)
                
                Text(formatTime(controller.duration))
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(width: 40, alignment: .leading)
            }
            
            // Playback Speed Menu
            Menu {
                Button("0.75x") { controller.setRate(0.75) }
                Button("1.0x (Normal)") { controller.setRate(1.0) }
                Button("1.25x") { controller.setRate(1.25) }
                Button("1.5x") { controller.setRate(1.5) }
                Button("2.0x") { controller.setRate(2.0) }
            } label: {
                Text(String(format: "%.2fx", controller.playbackRate).replacingOccurrences(of: ".00", with: ""))
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.secondary.opacity(0.12))
                    .cornerRadius(4)
            }
            .menuStyle(.borderlessButton)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
        )
        .onAppear {
            if let url = audioURL {
                controller.loadAudio(url: url)
            }
        }
        .onChange(of: audioURL) { _, newURL in
            if let newURL = newURL {
                controller.loadAudio(url: newURL)
            }
        }
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
