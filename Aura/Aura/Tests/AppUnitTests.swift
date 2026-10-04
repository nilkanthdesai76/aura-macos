//
//  AppUnitTests.swift
//  Granola
//

import Foundation
import AVFoundation

public final class AppUnitTests {
    public static func runAllTests() async -> (passed: Int, failed: Int, logs: [String]) {
        var passed = 0
        var failed = 0
        var logs: [String] = []
        
        func test(_ name: String, block: () async throws -> Void) async {
            do {
                try await block()
                passed += 1
                logs.append("✅ PASS: \(name)")
            } catch {
                failed += 1
                logs.append("❌ FAIL: \(name) - \(error.localizedDescription)")
            }
        }
        
        // 1. Meeting State Machine Tests
        await test("MeetingState isLive and Transitions") {
            let idle = MeetingState.idle
            assert(!idle.isLive, "Idle should not be live")
            
            let transcribing = MeetingState.transcribing
            assert(transcribing.isLive, "Transcribing should be live")
            
            let errorState = MeetingState.failed(.networkUnavailable)
            assert(!errorState.isLive, "Failed should not be live")
        }
        
        // 2. On-Device AI Synthesis & JSON Parsing Test
        await test("On-Device AI Synthesis & Structured JSON Parsing") {
            let aiService = AIService(provider: LocalOnDeviceAIProvider())
            let meetingID = UUID()
            let segmentID1 = UUID()
            let segmentID2 = UUID()
            
            let segments = [
                TranscriptSegment(
                    id: segmentID1,
                    meetingID: meetingID,
                    startTime: 0,
                    endTime: 3,
                    speaker: "Sarah",
                    text: "We agreed to launch the native macOS beta on Friday.",
                    confidence: 0.98,
                    isFinal: true
                ),
                TranscriptSegment(
                    id: segmentID2,
                    meetingID: meetingID,
                    startTime: 3,
                    endTime: 6,
                    speaker: "John",
                    text: "I will update the test suite today.",
                    confidence: 0.95,
                    isFinal: true
                )
            ]
            
            let userNotes = "- Beta launch Friday\n- Update test suite"
            let summary = try await aiService.synthesizeMeeting(
                meetingID: meetingID,
                userNotes: userNotes,
                segments: segments,
                recipe: .engineering
            )
            
            assert(!summary.summary.isEmpty, "Summary should not be empty")
            assert(!summary.decisions.isEmpty, "Decisions should be extracted")
            assert(!summary.actionItems.isEmpty, "Action items should be extracted")
            assert(summary.actionItems.first?.sourceSegmentIDs.isEmpty == false, "Action item must have source backlinks")
        }
        
        // 3. On-Device In-Meeting Q&A Test
        await test("On-Device In-Meeting Q&A Chat") {
            let aiService = AIService(provider: LocalOnDeviceAIProvider())
            let meetingID = UUID()
            let segments = [
                TranscriptSegment(
                    meetingID: meetingID,
                    startTime: 0,
                    endTime: 4,
                    speaker: "Sarah",
                    text: "We decided to allocate fifty thousand dollars for marketing.",
                    confidence: 0.98,
                    isFinal: true
                )
            ]
            
            let answer = try await aiService.answerMeetingQuestion(
                question: "What did we decide about marketing budget?",
                userNotes: "Budget discussion",
                segments: segments
            )
            
            assert(!answer.isEmpty, "Answer should not be empty")
            assert(answer.contains("marketing") || answer.contains("fifty thousand") || answer.contains("Sarah"), "Answer must contain relevant context")
        }
        
        // 4. Local Repository Save and Fetch Test
        await test("Local Repository Persistence") {
            let repo = LocalMeetingRepository()
            let testID = UUID()
            let testMeeting = Meeting(
                id: testID,
                title: "Test Unit Sync",
                startDate: Date(),
                duration: 120,
                userNotes: "Unit test notes"
            )
            
            try await repo.save(testMeeting)
            let fetched = try await repo.fetch(id: testID)
            assert(fetched?.title == "Test Unit Sync", "Fetched title must match saved title")
            
            try await repo.delete(id: testID)
            let deleted = try await repo.fetch(id: testID)
            assert(deleted == nil, "Meeting should be deleted")
        }
        
        // 5. Local Search Service Test
        await test("Full-Text Search Service") {
            let repo = LocalMeetingRepository()
            let searchID = UUID()
            let searchMeeting = Meeting(
                id: searchID,
                title: "Architecture Planning for PostgreSQL",
                startDate: Date(),
                duration: 300,
                userNotes: "Discussed database migration to PostgreSQL and Redis caching."
            )
            try await repo.save(searchMeeting)
            
            let searchService = SearchService(repository: repo)
            let results = await searchService.search(query: "PostgreSQL")
            assert(!results.isEmpty, "Search should find matching meeting for PostgreSQL")
            assert(results.first?.meetingID == searchID, "Search result should match searchID")
            
            try await repo.delete(id: searchID)
        }
        
        // 6. Audio Format Constants Test
        await test("Standard 16kHz Mono Format Invariant") {
            let format = StandardAudioFormat.processingFormat
            assert(format.sampleRate == 16000.0, "Sample rate must be 16kHz")
            assert(format.channelCount == 1, "Channel count must be 1 (Mono)")
        }
        
        return (passed, failed, logs)
    }
}
