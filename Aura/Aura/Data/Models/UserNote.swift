//
//  UserNote.swift
//  Granola
//

import Foundation

public struct UserNote: Identifiable, Codable, Sendable, Equatable {
    public let id: UUID
    public let meetingID: UUID
    public var text: String
    public var createdAt: Date
    public var updatedAt: Date
    public var position: Int
    
    public init(
        id: UUID = UUID(),
        meetingID: UUID,
        text: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        position: Int = 0
    ) {
        self.id = id
        self.meetingID = meetingID
        self.text = text
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.position = position
    }
}
