//
//  TranscriptStreamView.swift
//  Granola
//

import SwiftUI
import AppKit

public struct TranscriptStreamView: View {
    public let segments: [TranscriptSegment]
    public var highlightedSegmentID: UUID?
    public var onSeekAudio: ((TimeInterval) -> Void)?
    
    @State private var copied: Bool = false
    
    public init(
        segments: [TranscriptSegment],
        highlightedSegmentID: UUID? = nil,
        onSeekAudio: ((TimeInterval) -> Void)? = nil
    ) {
        self.segments = segments
        self.highlightedSegmentID = highlightedSegmentID
        self.onSeekAudio = onSeekAudio
    }
    
    private var fullTranscriptText: String {
        segments.map { $0.text }.filter { !$0.isEmpty }.joined(separator: "\n\n")
    }
    
    private var wordCount: Int {
        let words = fullTranscriptText.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        return words.count
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header Bar
            HStack(alignment: .center) {
                Label("Transcript", systemImage: "waveform")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if !fullTranscriptText.isEmpty {
                    Text("\(wordCount) words")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                    
                    Button {
                        copyTranscript()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 10))
                            Text(copied ? "Copied" : "Copy")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.secondary.opacity(0.12))
                        .cornerRadius(5)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 2)
            
            if fullTranscriptText.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "mic.bubble")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary.opacity(0.4))
                    Text("Listening for speech...")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    Text("Speak freely into your microphone. Your spoken notes will continuously transcribe here.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
                )
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 14) {
                            Text(fullTranscriptText)
                                .font(.system(size: 14, weight: .regular))
                                .lineSpacing(6)
                                .foregroundColor(.primary)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .id("transcript_bottom")
                            
                            if let lastSeg = segments.last, !lastSeg.isFinal {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(Color.orange)
                                        .frame(width: 6, height: 6)
                                    Text("Listening & transcribing...")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.orange)
                                }
                                .padding(.top, 4)
                            }
                        }
                        .padding(16)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(NSColor.controlBackgroundColor))
                    )
                    .onChange(of: fullTranscriptText) { _, _ in
                        withAnimation(.easeOut(duration: 0.15)) {
                            proxy.scrollTo("transcript_bottom", anchor: .bottom)
                        }
                    }
                }
            }
        }
    }
    
    private func copyTranscript() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(fullTranscriptText, forType: .string)
        copied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            copied = false
        }
    }
}
