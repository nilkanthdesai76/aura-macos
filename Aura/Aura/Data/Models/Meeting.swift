//
//  Meeting.swift
//  Granola
//

import Foundation

public struct Meeting: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public var title: String
    public var startDate: Date
    public var endDate: Date?
    public var duration: TimeInterval
    public var participants: [String]
    public var recipeID: String
    public var userNotes: String
    public var segments: [TranscriptSegment]
    public var summary: MeetingSummary?
    public var isStarred: Bool
    public var audioFileURL: URL?
    
    public init(
        id: UUID = UUID(),
        title: String = "Untitled Meeting",
        startDate: Date = Date(),
        endDate: Date? = nil,
        duration: TimeInterval = 0,
        participants: [String] = ["You"],
        recipeID: String = AIRecipe.standard.id,
        userNotes: String = "",
        segments: [TranscriptSegment] = [],
        summary: MeetingSummary? = nil,
        isStarred: Bool = false,
        audioFileURL: URL? = nil
    ) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.duration = duration
        self.participants = participants
        self.recipeID = recipeID
        self.userNotes = userNotes
        self.segments = segments
        self.summary = summary
        self.isStarred = isStarred
        self.audioFileURL = audioFileURL
    }
    
    public var computedAudioFileURL: URL? {
        if let explicit = audioFileURL, FileManager.default.fileExists(atPath: explicit.path) {
            return explicit
        }
        let recordingsDir = AudioRecorder.recordingsDirectory()
        let wavURL = recordingsDir.appendingPathComponent("\(id.uuidString).wav")
        if FileManager.default.fileExists(atPath: wavURL.path) {
            return wavURL
        }
        let m4aURL = recordingsDir.appendingPathComponent("\(id.uuidString).m4a")
        if FileManager.default.fileExists(atPath: m4aURL.path) {
            return m4aURL
        }
        return nil
    }
    
    public var hasAudioRecording: Bool {
        return computedAudioFileURL != nil
    }
    
    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: startDate)
    }
    
    public var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}
