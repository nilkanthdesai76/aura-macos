//
//  MeetingsListView.swift
//  Granola
//

import SwiftUI

public struct MeetingsListView: View {
    @Environment(AppState.self) private var appState
    
    public init() {}
    
    public var filteredMeetings: [Meeting] {
        switch appState.selectedSection {
        case .allMeetings:
            return appState.meetings
        case .upcoming:
            return appState.meetings.filter { $0.startDate > Date() }
        case .starred:
            return appState.meetings.filter { $0.isStarred }
        case .settings:
            return []
        }
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(appState.selectedSection.rawValue)
                    .font(.system(size: 14, weight: .bold))
                
                Spacer()
                
                Text("\(filteredMeetings.count)")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            
            Divider()
            
            if filteredMeetings.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "note.text")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary.opacity(0.4))
                    Text("No meetings found")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                List(filteredMeetings, selection: Bindable(appState).selectedMeetingID) { meeting in
                    MeetingRowView(meeting: meeting)
                        .tag(meeting.id)
                }
                .listStyle(.sidebar)
            }
        }
    }
}

public struct MeetingRowView: View {
    public let meeting: Meeting
    
    public init(meeting: Meeting) {
        self.meeting = meeting
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(meeting.title)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                
                Spacer()
                
                if meeting.isStarred {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.yellow)
                }
            }
            
            HStack(spacing: 6) {
                Text(meeting.formattedDate)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                
                Text("•")
                    .foregroundColor(.secondary)
                
                Text(meeting.formattedDuration)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            
            if let summary = meeting.summary?.summary {
                Text(summary)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 4)
    }
}
