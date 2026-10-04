//
//  AIService.swift
//  Granola
//

import Foundation
import OSLog

public actor AIService {
    private var provider: AIProvider
    
    public init(provider: AIProvider = LocalOnDeviceAIProvider()) {
        self.provider = provider
    }
    
    public func setProvider(_ provider: AIProvider) {
        self.provider = provider
    }
    
    public func synthesizeMeeting(
        meetingID: UUID,
        userNotes: String,
        segments: [TranscriptSegment],
        recipe: AIRecipe
    ) async throws -> MeetingSummary {
        let systemPrompt = PromptManager.coreSynthesisSystemPrompt
        let userPrompt = PromptManager.buildSynthesisPrompt(userNotes: userNotes, segments: segments, recipe: recipe)
        
        AppLog.ai.info("Starting AI synthesis for meeting: \(meetingID)")
        
        let rawResponse = try await provider.generateCompletion(systemPrompt: systemPrompt, userPrompt: userPrompt)
        
        // Clean JSON response (strip markdown code blocks ```json ... ```)
        let cleanedJSON = cleanJSONResponse(rawResponse)
        
        guard let data = cleanedJSON.data(using: .utf8) else {
            throw AIProviderError.invalidResponse("Could not convert AI response to UTF-8 data")
        }
        
        do {
            let decoder = JSONDecoder()
            struct DecodedSummary: Decodable {
                let summary: String
                let discussionPoints: [DiscussionPoint]
                let decisions: [Decision]
                let actionItems: [ActionItem]
                let openQuestions: [OpenQuestion]
                let quotes: [ImportantQuote]
            }
            
            let decoded = try decoder.decode(DecodedSummary.self, from: data)
            
            let meetingSummary = MeetingSummary(
                meetingID: meetingID,
                summary: decoded.summary,
                discussionPoints: decoded.discussionPoints,
                decisions: decoded.decisions,
                actionItems: decoded.actionItems,
                openQuestions: decoded.openQuestions,
                quotes: decoded.quotes,
                generatedAt: Date()
            )
            
            AppLog.ai.info("AI synthesis completed successfully for meeting: \(meetingID)")
            return meetingSummary
        } catch {
            AppLog.ai.error("JSON decoding failed for AI output: \(error.localizedDescription)")
            throw AIProviderError.invalidResponse("Failed to parse structured JSON: \(error.localizedDescription)")
        }
    }
    
    public func answerMeetingQuestion(
        question: String,
        userNotes: String,
        segments: [TranscriptSegment]
    ) async throws -> String {
        var transcriptContext = ""
        for seg in segments {
            let startMin = Int(seg.startTime) / 60
            let startSec = Int(seg.startTime) % 60
            let timeStr = String(format: "%02d:%02d", startMin, startSec)
            transcriptContext += "[\(timeStr)] \(seg.speaker): \(seg.text)\n"
        }
        
        let systemPrompt = """
        You are an AI meeting assistant. Answer the user's question based ONLY on the provided meeting transcript and notes.
        If the information is not present in the transcript or notes, explicitly say: "This was not discussed during the meeting."
        Always cite timestamps or speaker quotes where possible.
        """
        
        let userPrompt = """
        # MEETING NOTES:
        \(userNotes)

        # TRANSCRIPT:
        \(transcriptContext)

        # USER QUESTION:
        \(question)
        """
        
        return try await provider.generateCompletion(systemPrompt: systemPrompt, userPrompt: userPrompt)
    }
    
    private func cleanJSONResponse(_ response: String) -> String {
        var trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("```json") {
            trimmed = String(trimmed.dropFirst(7))
        } else if trimmed.hasPrefix("```") {
            trimmed = String(trimmed.dropFirst(3))
        }
        if trimmed.hasSuffix("```") {
            trimmed = String(trimmed.dropLast(3))
        }
        return trimmed.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
