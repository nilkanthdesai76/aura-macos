//
//  CommandPaletteView.swift
//  Granola
//

import SwiftUI

public struct CommandPaletteView: View {
    @Environment(AppState.self) private var appState
    @State private var query: String = ""
    @State private var results: [SearchResult] = []
    @State private var isSearching: Bool = false
    
    private let searchService = DependencyContainer.shared.searchService
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Search Input Header
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 16))
                
                TextField("Search notes, transcripts, decisions, action items...", text: $query)
                    .font(.system(size: 15))
                    .textFieldStyle(.plain)
                    .onChange(of: query) { _, newQuery in
                        performSearch(query: newQuery)
                    }
                
                if !query.isEmpty {
                    Button {
                        query = ""
                        results = []
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                
                Text("ESC")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.15))
                    .cornerRadius(4)
                    .foregroundColor(.secondary)
            }
            .padding(14)
            
            Divider()
            
            // Search Results List
            if results.isEmpty && !query.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Text("No matching results found for \"\(query)\"")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(height: 240)
            } else if results.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Quick Actions")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    QuickActionRow(title: "Start New Meeting", icon: "mic.fill", shortcut: "⌘Enter") {
                        appState.isCommandPalettePresented = false
                        appState.startNewMeeting()
                    }
                    
                    QuickActionRow(title: "View All Meetings", icon: "bubble.left.and.bubble.right", shortcut: "⌘1") {
                        appState.isCommandPalettePresented = false
                        appState.selectedSection = .allMeetings
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                List(results) { res in
                    Button {
                        appState.selectedMeetingID = res.meetingID
                        appState.selectedSection = .allMeetings
                        appState.isCommandPalettePresented = false
                    } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text(res.meetingTitle)
                                    .font(.system(size: 13, weight: .semibold))
                                
                                Spacer()
                                
                                Text(res.matchCategory.rawValue)
                                    .font(.system(size: 10, weight: .medium))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.accentColor.opacity(0.12))
                                    .cornerRadius(4)
                            }
                            
                            Text(res.snippet)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.plain)
                .frame(height: 300)
            }
        }
        .frame(width: 560)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 20)
    }
    
    private func performSearch(query: String) {
        Task {
            let res = await searchService.search(query: query)
            self.results = res
        }
    }
}

private struct QuickActionRow: View {
    let title: String
    let icon: String
    let shortcut: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .frame(width: 20)
                
                Text(title)
                    .font(.system(size: 13))
                
                Spacer()
                
                Text(shortcut)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}
