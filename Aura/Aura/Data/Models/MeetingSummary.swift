//
//  MeetingSummary.swift
//  Granola
//

import Foundation

public struct DiscussionPoint: Identifiable, Codable, Sendable, Equatable {
    public var id: UUID
    public var topic: String
    public var details: String
    public var userNoteAnchor: String?
    public var sourceSegmentIDs: [UUID]
    
    public init(
        id: UUID = UUID(),
        topic: String,
        details: String,
        userNoteAnchor: String? = nil,
        sourceSegmentIDs: [UUID] = []
    ) {
        self.id = id
        self.topic = topic
        self.details = details
        self.userNoteAnchor = userNoteAnchor
        self.sourceSegmentIDs = sourceSegmentIDs
    }
}

public struct Decision: Identifiable, Codable, Sendable, Equatable {
    public var id: UUID
    public var content: String
    public var decidedBy: String?
    public var sourceSegmentIDs: [UUID]
    
    public init(
        id: UUID = UUID(),
        content: String,
        decidedBy: String? = nil,
        sourceSegmentIDs: [UUID] = []
    ) {
        self.id = id
        self.content = content
        self.decidedBy = decidedBy
        self.sourceSegmentIDs = sourceSegmentIDs
    }
}

public struct ActionItem: Identifiable, Codable, Sendable, Equatable {
    public var id: UUID
    public var title: String
    public var owner: String?
    public var deadline: String?
    public var isCompleted: Bool
    public var sourceSegmentIDs: [UUID]
    
    public init(
        id: UUID = UUID(),
        title: String,
        owner: String? = nil,
        deadline: String? = nil,
        isCompleted: Bool = false,
        sourceSegmentIDs: [UUID] = []
    ) {
        self.id = id
        self.title = title
        self.owner = owner
        self.deadline = deadline
        self.isCompleted = isCompleted
        self.sourceSegmentIDs = sourceSegmentIDs
    }
}

public struct OpenQuestion: Identifiable, Codable, Sendable, Equatable {
    public var id: UUID
    public var question: String
    public var raisedBy: String?
    public var sourceSegmentIDs: [UUID]
    
    public init(
        id: UUID = UUID(),
        question: String,
        raisedBy: String? = nil,
        sourceSegmentIDs: [UUID] = []
    ) {
        self.id = id
        self.question = question
        self.raisedBy = raisedBy
        self.sourceSegmentIDs = sourceSegmentIDs
    }
}

public struct ImportantQuote: Identifiable, Codable, Sendable, Equatable {
    public var id: UUID
    public var quote: String
    public var speaker: String
    public var timestamp: Double
    public var sourceSegmentID: UUID
    
    public init(
        id: UUID = UUID(),
        quote: String,
        speaker: String,
        timestamp: Double = 0,
        sourceSegmentID: UUID
    ) {
        self.id = id
        self.quote = quote
        self.speaker = speaker
        self.timestamp = timestamp
        self.sourceSegmentID = sourceSegmentID
    }
}

public struct MeetingSummary: Identifiable, Codable, Sendable, Equatable {
    public var id: UUID
    public var meetingID: UUID
    public var summary: String
    public var discussionPoints: [DiscussionPoint]
    public var decisions: [Decision]
    public var actionItems: [ActionItem]
    public var openQuestions: [OpenQuestion]
    public var quotes: [ImportantQuote]
    public var generatedAt: Date
    
    public init(
        id: UUID = UUID(),
        meetingID: UUID,
        summary: String,
        discussionPoints: [DiscussionPoint] = [],
        decisions: [Decision] = [],
        actionItems: [ActionItem] = [],
        openQuestions: [OpenQuestion] = [],
        quotes: [ImportantQuote] = [],
        generatedAt: Date = Date()
    ) {
        self.id = id
        self.meetingID = meetingID
        self.summary = summary
        self.discussionPoints = discussionPoints
        self.decisions = decisions
        self.actionItems = actionItems
        self.openQuestions = openQuestions
        self.quotes = quotes
        self.generatedAt = generatedAt
    }
}
