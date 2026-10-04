//
//  MeetingRepository.swift
//  Granola
//

import Foundation
import OSLog

public protocol MeetingRepository: Actor {
    func save(_ meeting: Meeting) async throws
    func fetch(id: UUID) async throws -> Meeting?
    func fetchAll() async throws -> [Meeting]
    func delete(id: UUID) async throws
    func toggleStarred(id: UUID) async throws
}

public actor LocalMeetingRepository: MeetingRepository {
    public static let shared = LocalMeetingRepository()
    
    private var meetings: [UUID: Meeting] = [:]
    private let storageURL: URL
    
    public init() {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? fileManager.temporaryDirectory
        let dir = appSupport.appendingPathComponent("com.nilkanth.Granola", isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        self.storageURL = dir.appendingPathComponent("meetings_store.json")
        loadFromDisk()
    }
    
    public func save(_ meeting: Meeting) async throws {
        meetings[meeting.id] = meeting
        saveToDisk()
        AppLog.data.info("Saved meeting '\(meeting.title)' (\(meeting.id))")
    }
    
    public func fetch(id: UUID) async throws -> Meeting? {
        return meetings[id]
    }
    
    public func fetchAll() async throws -> [Meeting] {
        return meetings.values.sorted(by: { $0.startDate > $1.startDate })
    }
    
    public func delete(id: UUID) async throws {
        meetings.removeValue(forKey: id)
        saveToDisk()
        AppLog.data.info("Deleted meeting: \(id)")
    }
    
    public func toggleStarred(id: UUID) async throws {
        guard var meeting = meetings[id] else { return }
        meeting.isStarred.toggle()
        meetings[id] = meeting
        saveToDisk()
    }
    
    private func saveToDisk() {
        let list = Array(meetings.values)
        do {
            let data = try JSONEncoder().encode(list)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            AppLog.data.error("Failed to persist meetings to disk: \(error.localizedDescription)")
        }
    }
    
    private func loadFromDisk() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else { return }
        do {
            let data = try Data(contentsOf: storageURL)
            let list = try JSONDecoder().decode([Meeting].self, from: data)
            for m in list {
                self.meetings[m.id] = m
            }
            AppLog.data.info("Loaded \(list.count) meetings from disk.")
        } catch {
            AppLog.data.error("Failed to load meetings from disk: \(error.localizedDescription)")
        }
    }
}
