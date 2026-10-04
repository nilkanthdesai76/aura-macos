//
//  SearchService.swift
//  Granola
//

import Foundation

public struct SearchResult: Identifiable, Sendable, Equatable {
    public let id = UUID()
    public let meetingID: UUID
    public let meetingTitle: String
    public let meetingDate: Date
    public let matchCategory: MatchCategory
    public let snippet: String
    public let targetSegmentID: UUID?
    
    public enum MatchCategory: String, Sendable {
        case title = "Title"
        case userNotes = "My Notes"
        case transcript = "Transcript"
        case decision = "Decision"
        case actionItem = "Action Item"
        case summary = "Summary"
    }
}

public actor SearchService {
    private let repository: any MeetingRepository
    
    public init(repository: any MeetingRepository = LocalMeetingRepository.shared) {
        self.repository = repository
    }
    
    public func search(query: String) async -> [SearchResult] {
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !cleanQuery.isEmpty else { return [] }
        
        guard let allMeetings = try? await repository.fetchAll() else { return [] }
        var results: [SearchResult] = []
        
        for meeting in allMeetings {
            // 1. Check Title
            if meeting.title.lowercased().contains(cleanQuery) {
                results.append(SearchResult(
                    meetingID: meeting.id,
                    meetingTitle: meeting.title,
                    meetingDate: meeting.startDate,
                    matchCategory: .title,
                    snippet: meeting.title,
                    targetSegmentID: nil
                ))
            }
            
            // 2. Check User Notes
            if meeting.userNotes.lowercased().contains(cleanQuery) {
                let snippet = extractSnippet(from: meeting.userNotes, matching: cleanQuery)
                results.append(SearchResult(
                    meetingID: meeting.id,
                    meetingTitle: meeting.title,
                    meetingDate: meeting.startDate,
                    matchCategory: .userNotes,
                    snippet: snippet,
                    targetSegmentID: nil
                ))
            }
            
            // 3. Check Transcript Segments
            for seg in meeting.segments {
                if seg.text.lowercased().contains(cleanQuery) {
                    results.append(SearchResult(
                        meetingID: meeting.id,
                        meetingTitle: meeting.title,
                        meetingDate: meeting.startDate,
                        matchCategory: .transcript,
                        snippet: "\(seg.speaker): \(seg.text)",
                        targetSegmentID: seg.id
                    ))
                }
            }
            
            // 4. Check Decisions & Action Items in Summary
            if let summary = meeting.summary {
                for dec in summary.decisions {
                    if dec.content.lowercased().contains(cleanQuery) {
                        results.append(SearchResult(
                            meetingID: meeting.id,
                            meetingTitle: meeting.title,
                            meetingDate: meeting.startDate,
                            matchCategory: .decision,
                            snippet: dec.content,
                            targetSegmentID: dec.sourceSegmentIDs.first
                        ))
                    }
                }
                
                for act in summary.actionItems {
                    if act.title.lowercased().contains(cleanQuery) {
                        results.append(SearchResult(
                            meetingID: meeting.id,
                            meetingTitle: meeting.title,
                            meetingDate: meeting.startDate,
                            matchCategory: .actionItem,
                            snippet: "\(act.title) (Assignee: \(act.owner ?? "Unassigned"))",
                            targetSegmentID: act.sourceSegmentIDs.first
                        ))
                    }
                }
            }
        }
        
        return results
    }
    
    private func extractSnippet(from fullText: String, matching query: String) -> String {
        guard let range = fullText.range(of: query, options: .caseInsensitive) else {
            return String(fullText.prefix(100))
        }
        
        let start = fullText.index(range.lowerBound, offsetBy: -40, limitedBy: fullText.startIndex) ?? fullText.startIndex
        let end = fullText.index(range.upperBound, offsetBy: 60, limitedBy: fullText.endIndex) ?? fullText.endIndex
        
        var snippet = String(fullText[start..<end])
        if start > fullText.startIndex { snippet = "..." + snippet }
        if end < fullText.endIndex { snippet = snippet + "..." }
        return snippet.replacingOccurrences(of: "\n", with: " ")
    }
}
