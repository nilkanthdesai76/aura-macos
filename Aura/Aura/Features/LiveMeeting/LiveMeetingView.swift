//
//  LiveMeetingView.swift
//  Granola
//

import SwiftUI

public struct LiveMeetingView: View {
    @State private var viewModel = LiveMeetingViewModel()
    @Environment(AppState.self) private var appState
    
    @State private var customTitle: String = ""
    @State private var selectedRecipe: AIRecipe = .standard
    @State private var isStopping: Bool = false
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 3) {
                    TextField("Meeting Title", text: $viewModel.meetingTitle)
                        .font(.system(size: 18, weight: .bold))
                        .textFieldStyle(.plain)
                    
                    HStack(spacing: 8) {
                        Text(formatDuration(viewModel.durationElapsed))
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Menu {
                            ForEach(AIRecipe.allDefaultRecipes) { recipe in
                                Button {
                                    viewModel.selectedRecipe = recipe
                                } label: {
                                    Label(recipe.name, systemImage: recipe.icon)
                                }
                            }
                        } label: {
                            Label(viewModel.selectedRecipe.name, systemImage: viewModel.selectedRecipe.icon)
                                .font(.system(size: 11, weight: .medium))
                        }
                        .menuStyle(.borderlessButton)
                    }
                }
                
                Spacer()
                
                // Live Audio Level Meter
                AudioLevelMeterView(
                    level: viewModel.audioLevel,
                    isRecording: viewModel.state.isLive
                )
                
                // Stop / Finish Button
                Button {
                    Task {
                        isStopping = true
                        if let savedMeeting = await viewModel.stopMeeting() {
                            await appState.refreshMeetings()
                            appState.selectedMeetingID = savedMeeting.id
                            appState.isLiveMeetingActive = false
                        }
                        isStopping = false
                    }
                } label: {
                    HStack(spacing: 6) {
                        if isStopping || viewModel.state == .processing {
                            ProgressView()
                                .controlSize(.small)
                            Text("Enhancing...")
                                .font(.system(size: 12, weight: .semibold))
                        } else {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 10))
                            Text("Stop & Enhance")
                                .font(.system(size: 12, weight: .semibold))
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .foregroundColor(.white)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red)
                    )
                }
                .buttonStyle(.plain)
                .disabled(isStopping || viewModel.state == .processing)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Main Content Area: Split View of My Notes & Live Transcript
            HSplitView {
                NotesEditorView(text: $viewModel.userNotes)
                    .frame(minWidth: 320, maxWidth: .infinity)
                    .padding(16)
                
                TranscriptStreamView(segments: viewModel.liveSegments)
                    .frame(minWidth: 360, maxWidth: .infinity)
                    .padding(16)
            }
            .background(Color(NSColor.underPageBackgroundColor))
            
            Divider()
            
            // Bottom Status Bar
            HStack(spacing: 12) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(viewModel.state.isLive ? Color.green : Color.secondary)
                        .frame(width: 6, height: 6)
                    
                    Text(viewModel.state.titleDescription)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                if viewModel.state.isLive {
                    HStack(spacing: 4) {
                        Image(systemName: "record.circle")
                            .foregroundColor(.red)
                            .font(.system(size: 10))
                        Text("Recording Audio (.m4a)")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(4)
                }
                
                Spacer()
                
                Text("On-Device AI • Privacy First")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                
                Button("Discard") {
                    Task {
                        _ = await viewModel.stopMeeting()
                        appState.isLiveMeetingActive = false
                    }
                }
                .font(.system(size: 11))
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
        }
        .task {
            if viewModel.state == .idle {
                await viewModel.startMeeting()
            }
        }
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
