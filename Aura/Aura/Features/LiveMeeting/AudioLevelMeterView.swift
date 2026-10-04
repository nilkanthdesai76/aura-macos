//
//  AudioLevelMeterView.swift
//  Granola
//

import SwiftUI

public struct AudioLevelMeterView: View {
    public let level: AudioLevel
    public let isRecording: Bool
    
    public init(level: AudioLevel, isRecording: Bool) {
        self.level = level
        self.isRecording = isRecording
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            // Pulsing Recording Dot
            HStack(spacing: 6) {
                Circle()
                    .fill(isRecording ? Color.red : Color.secondary)
                    .frame(width: 8, height: 8)
                    .opacity(isRecording ? 1.0 : 0.4)
                
                Text(isRecording ? "LIVE" : "PAUSED")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(isRecording ? .red : .secondary)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(isRecording ? Color.red.opacity(0.12) : Color.secondary.opacity(0.1))
            )
            
            Divider()
                .frame(height: 14)
            
            // Microphone Level Bar
            HStack(spacing: 5) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                
                LevelBar(value: level.micLevel, activeColor: .blue)
                    .frame(width: 60, height: 5)
            }
            
            // System Audio Level Bar
            HStack(spacing: 5) {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                
                LevelBar(value: level.systemLevel, activeColor: .purple)
                    .frame(width: 60, height: 5)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
}

private struct LevelBar: View {
    let value: Float
    let activeColor: Color
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.secondary.opacity(0.2))
                
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [activeColor.opacity(0.8), activeColor],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(2, geometry.size.width * CGFloat(value)))
                    .animation(.easeOut(duration: 0.08), value: value)
            }
        }
    }
}
