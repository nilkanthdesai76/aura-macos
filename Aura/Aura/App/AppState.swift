//
//  AppState.swift
//  Granola
//

import Foundation
import SwiftUI
import OSLog

public enum SidebarSection: String, CaseIterable, Identifiable {
    case allMeetings = "All Meetings"
    case upcoming = "Upcoming"
    case starred = "Starred"
    case settings = "Settings"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .allMeetings: return "bubble.left.and.bubble.right"
        case .upcoming: return "calendar"
        case .starred: return "star"
        case .settings: return "gearshape"
        }
    }
}

@MainActor
@Observable
public final class AppState {
    public var selectedSection: SidebarSection = .allMeetings
    public var selectedMeetingID: UUID?
    public var isLiveMeetingActive: Bool = false
    public var isCommandPalettePresented: Bool = false
    public var meetings: [Meeting] = []
    public var errorMessage: String?
    public var isShowingErrorAlert: Bool = false
    
    private let repository: LocalMeetingRepository
    
    public init(repository: LocalMeetingRepository = LocalMeetingRepository.shared) {
        self.repository = repository
        Task {
            await refreshMeetings()
            #if DEBUG
            let (passed, failed, logs) = await AppUnitTests.runAllTests()
            AppLog.general.info("AppUnitTests finished: \(passed) passed, \(failed) failed.")
            for log in logs {
                AppLog.general.info("\(log)")
            }
            #endif
        }
    }
    
    public func refreshMeetings() async {
        do {
            self.meetings = try await repository.fetchAll()
            if selectedMeetingID == nil, let first = self.meetings.first {
                self.selectedMeetingID = first.id
            }
        } catch {
            AppLog.data.error("Failed to load meetings: \(error.localizedDescription)")
        }
    }
    
    public func startNewMeeting() {
        self.isLiveMeetingActive = true
    }
    
    public func deleteMeeting(id: UUID) async {
        do {
            try await repository.delete(id: id)
            if selectedMeetingID == id {
                selectedMeetingID = nil
            }
            await refreshMeetings()
        } catch {
            showError("Failed to delete meeting: \(error.localizedDescription)")
        }
    }
    
    public func toggleStarred(id: UUID) async {
        do {
            try await repository.toggleStarred(id: id)
            await refreshMeetings()
        } catch {
            showError("Failed to update star: \(error.localizedDescription)")
        }
    }
    
    public func showError(_ message: String) {
        self.errorMessage = message
        self.isShowingErrorAlert = true
    }
}
