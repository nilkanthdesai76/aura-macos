//
//  ContentView.swift
//  Granola
//

import SwiftUI

struct ContentView: View {
    @State private var appState = AppState()
    
    var body: some View {
        Group {
            if appState.isLiveMeetingActive {
                LiveMeetingView()
            } else {
                NavigationSplitView {
                    // Sidebar
                    List(SidebarSection.allCases, selection: $appState.selectedSection) { section in
                        NavigationLink(value: section) {
                            Label(section.rawValue, systemImage: section.iconName)
                        }
                    }
                    .listStyle(.sidebar)
                    .frame(minWidth: 180)
                } content: {
                    // Middle Column: Meeting List or Settings
                    switch appState.selectedSection {
                    case .allMeetings, .upcoming, .starred:
                        MeetingsListView()
                            .frame(minWidth: 260)
                    case .settings:
                        Text("Settings")
                            .font(.headline)
                            .padding()
                    }
                } detail: {
                    // Detail Column
                    switch appState.selectedSection {
                    case .settings:
                        SettingsView()
                    case .allMeetings, .upcoming, .starred:
                        if let selectedID = appState.selectedMeetingID,
                           let meeting = appState.meetings.first(where: { $0.id == selectedID }) {
                            MeetingDetailView(meeting: meeting)
                        } else {
                            HomeDashboardView()
                        }
                    }
                }
            }
        }
        .environment(appState)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    appState.startNewMeeting()
                } label: {
                    Label("Start Meeting", systemImage: "mic.fill")
                }
                .disabled(appState.isLiveMeetingActive)
            }
            
            ToolbarItem(placement: .automatic) {
                Button {
                    appState.isCommandPalettePresented = true
                } label: {
                    Image(systemName: "magnifyingglass")
                }
                .keyboardShortcut("k", modifiers: .command)
                .help("Search (⌘K)")
            }
        }
        .sheet(isPresented: $appState.isCommandPalettePresented) {
            CommandPaletteView()
                .environment(appState)
                .padding()
        }
    }
}
