//
//  TranscriptSegment.swift
//  Granola
//

import Foundation

public struct TranscriptSegment: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public let meetingID: UUID
    
    public var startTime: TimeInterval
    public var endTime: TimeInterval
    
    public var speaker: String
    public var text: String
    
    public var confidence: Float?
    public var isFinal: Bool
    
    public init(
        id: UUID = UUID(),
        meetingID: UUID,
        startTime: TimeInterval,
        endTime: TimeInterval,
        speaker: String = "Speaker 1",
        text: String,
        confidence: Float? = 0.95,
        isFinal: Bool = false
    ) {
        self.id = id
        self.meetingID = meetingID
        self.startTime = startTime
        self.endTime = endTime
        self.speaker = speaker
        self.text = text
        self.confidence = confidence
        self.isFinal = isFinal
    }
}
