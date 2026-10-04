//
//  HomeDashboardView.swift
//  Granola
//

import SwiftUI

public struct HomeDashboardView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedRecipe: AIRecipe = .standard
    @State private var meetingTitleInput: String = ""
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Welcome / Hero Banner
                VStack(alignment: .leading, spacing: 6) {
                    Text("Meeting Memory")
                        .font(.system(size: 24, weight: .bold))
                    Text("Capture calls invisibly with on-device AI transcription and synthesis.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                // Quick Start Card
                VStack(alignment: .leading, spacing: 14) {
                    Label("Start a Meeting", systemImage: "mic.circle.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 12) {
                        TextField("Meeting Title (e.g., Weekly Sync, Product Review)", text: $meetingTitleInput)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(size: 13))
                        
                        Picker("", selection: $selectedRecipe) {
                            ForEach(AIRecipe.allDefaultRecipes) { r in
                                Text(r.name).tag(r)
                            }
                        }
                        .frame(width: 160)
                        
                        Button {
                            appState.startNewMeeting()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "record.circle")
                                Text("Start Notes")
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.return, modifiers: .command)
                    }
                    
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "lock.shield.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.green)
                            Text("100% On-Device AI")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "waveform")
                                .font(.system(size: 11))
                                .foregroundColor(.blue)
                            Text("Mic + System Audio Loopback")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("Shortcut: ⌘Enter")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(NSColor.controlBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
                )
                
                // Recent Meetings
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Meetings")
                        .font(.system(size: 16, weight: .bold))
                    
                    if appState.meetings.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 32))
                                .foregroundColor(.secondary.opacity(0.4))
                            Text("No recorded meetings yet")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                            Text("Click 'Start Notes' above or press ⌘Enter during your next call.")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 36)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(NSColor.controlBackgroundColor).opacity(0.4))
                        )
                    } else {
                        LazyVStack(spacing: 10) {
                            ForEach(appState.meetings.prefix(5)) { meeting in
                                Button {
                                    appState.selectedMeetingID = meeting.id
                                    appState.selectedSection = .allMeetings
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(meeting.title)
                                                .font(.system(size: 13, weight: .semibold))
                                            Text("\(meeting.formattedDate) • \(meeting.formattedDuration)")
                                                .font(.system(size: 11))
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(NSColor.controlBackgroundColor))
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
    }
}
