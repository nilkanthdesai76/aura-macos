//
//  MeetingDetailView.swift
//  Granola
//

import SwiftUI

public enum MeetingTab: String, CaseIterable, Identifiable {
    case myNotes = "My Notes"
    case enhanced = "Enhanced Notes ★"
    case transcript = "Transcript"
    
    public var id: String { rawValue }
}

public struct MeetingDetailView: View {
    public let meeting: Meeting
    @Environment(AppState.self) private var appState
    
    @StateObject private var audioPlayerController = AudioPlayerController()
    @State private var selectedTab: MeetingTab = .enhanced
    @State private var highlightedSegmentID: UUID?
    @State private var isShowingChatInspector: Bool = false
    @State private var editableNotes: String = ""
    
    public init(meeting: Meeting) {
        self.meeting = meeting
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(meeting.title)
                            .font(.system(size: 20, weight: .bold))
                        
                        Button {
                            Task {
                                await appState.toggleStarred(id: meeting.id)
                            }
                        } label: {
                            Image(systemName: meeting.isStarred ? "star.fill" : "star")
                                .foregroundColor(meeting.isStarred ? .yellow : .secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    HStack(spacing: 8) {
                        Text(meeting.formattedDate)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text(meeting.formattedDuration)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text(meeting.participants.joined(separator: ", "))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Action Buttons
                HStack(spacing: 10) {
                    Button {
                        isShowingChatInspector.toggle()
                    } label: {
                        Label("Ask AI", systemImage: "bubble.left.and.text.bubble.right")
                            .font(.system(size: 12, weight: .medium))
                    }
                    
                    Button {
                        exportToClipboard()
                    } label: {
                        Label("Copy Summary", systemImage: "doc.on.doc")
                            .font(.system(size: 12, weight: .medium))
                    }
                    
                    Button(role: .destructive) {
                        Task {
                            await appState.deleteMeeting(id: meeting.id)
                        }
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color(NSColor.windowBackgroundColor))
            
            // Audio Player Bar (if recording is available)
            if let audioURL = meeting.computedAudioFileURL {
                Divider()
                AudioPlayerView(controller: audioPlayerController, audioURL: audioURL)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color(NSColor.controlBackgroundColor).opacity(0.4))
            }
            
            Divider()
            
            // Tab Selector
            HStack {
                Picker("", selection: $selectedTab) {
                    ForEach(MeetingTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 380)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            
            Divider()
            
            // Tab Content
            HSplitView {
                Group {
                    switch selectedTab {
                    case .myNotes:
                        VStack(alignment: .leading) {
                            TextEditor(text: $editableNotes)
                                .font(.system(size: 14))
                                .padding(16)
                                .scrollContentBackground(.hidden)
                        }
                        .background(Color(NSColor.textBackgroundColor))
                        
                    case .enhanced:
                        EnhancedNotesView(summary: meeting.summary) { targetID in
                            self.highlightedSegmentID = targetID
                            self.selectedTab = .transcript
                            if let targetSeg = meeting.segments.first(where: { $0.id == targetID }) {
                                audioPlayerController.seek(to: targetSeg.startTime)
                            }
                        }
                        .background(Color(NSColor.underPageBackgroundColor))
                        
                    case .transcript:
                        TranscriptStreamView(
                            segments: meeting.segments,
                            highlightedSegmentID: highlightedSegmentID,
                            onSeekAudio: { time in
                                audioPlayerController.seek(to: time)
                            }
                        )
                        .padding(16)
                        .background(Color(NSColor.underPageBackgroundColor))
                    }
                }
                .frame(minWidth: 400, maxWidth: .infinity)
                
                // Collapsible In-Meeting AI Chat Panel
                if isShowingChatInspector {
                    InMeetingChatView(meeting: meeting)
                        .frame(width: 320)
                        .transition(.move(edge: .trailing))
                }
            }
        }
        .onAppear {
            self.editableNotes = meeting.userNotes
            if let audioURL = meeting.computedAudioFileURL {
                audioPlayerController.loadAudio(url: audioURL)
            }
        }
        .onDisappear {
            audioPlayerController.stop()
        }
    }
    
    private func exportToClipboard() {
        guard let summary = meeting.summary else { return }
        var export = "# \(meeting.title)\n\n## Executive Summary\n\(summary.summary)\n\n"
        if !summary.decisions.isEmpty {
            export += "## Key Decisions\n"
            for d in summary.decisions { export += "- \(d.content)\n" }
            export += "\n"
        }
        if !summary.actionItems.isEmpty {
            export += "## Action Items\n"
            for a in summary.actionItems { export += "- [ ] \(a.title) (\(a.owner ?? "Unassigned"))\n" }
        }
        
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(export, forType: .string)
    }
}
