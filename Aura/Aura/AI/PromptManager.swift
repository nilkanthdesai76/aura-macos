//
//  PromptManager.swift
//  Granola
//

import Foundation

public enum PromptManager {
    public static let systemPromptVersion = "1.0.0"
    
    public static let coreSynthesisSystemPrompt = """
    You are an expert meeting intelligence assistant.
    Transform the supplied transcript and user shorthand notes into accurate, structured, executive-ready meeting documentation.

    # STRICT GROUNDING RULES:
    1. STRICT GROUNDING: Extract facts, decisions, and action items ONLY from the provided transcript.
    2. NEVER INVENT: Never fabricate decisions, commitments, action items, dates, names, or quotes.
    3. PRESERVE UNCERTAINTY: If a discussion was inconclusive, explicitly state that no consensus was reached.
    4. HUMAN-IN-THE-LOOP PRIORITY: Treat the user's notes as primary attention anchors. Expand upon the user's bullet points using facts and quotes from the transcript.
    5. SOURCE LINKING: Every extracted Action Item and Decision MUST include the exact `sourceSegmentIDs` (UUIDs of the transcript segments from which they were derived).
    6. EXACT QUOTES ONLY: Important quotes must be verbatim excerpts from the transcript.
    7. JSON ONLY: Output valid JSON matching the exact schema requested. Do not wrap in conversational preamble.
    """
    
    public static func buildSynthesisPrompt(
        userNotes: String,
        segments: [TranscriptSegment],
        recipe: AIRecipe
    ) -> String {
        var transcriptFormatted = ""
        for (index, seg) in segments.enumerated() {
            let startMin = Int(seg.startTime) / 60
            let startSec = Int(seg.startTime) % 60
            let timeStr = String(format: "%02d:%02d", startMin, startSec)
            transcriptFormatted += "[ID: \(seg.id.uuidString)] [\(timeStr)] \(seg.speaker): \(seg.text)\n"
        }
        
        return """
        # MEETING RECIPE / FOCUS:
        \(recipe.name): \(recipe.promptDirective)

        # USER RAW NOTES (HIGH PRIORITY ANCHORS):
        \(userNotes.isEmpty ? "(No manual notes taken)" : userNotes)

        # FULL DIARIZED TRANSCRIPT:
        \(transcriptFormatted.isEmpty ? "(No audio transcribed)" : transcriptFormatted)

        # JSON SCHEMA OUTPUT REQUIREMENT:
        Provide output matching this JSON structure:
        {
          "summary": "Crisp 2-3 paragraph executive overview",
          "discussionPoints": [
            {
              "topic": "Topic title",
              "details": "Thorough breakdown expanded with transcript evidence",
              "userNoteAnchor": "Matching user note if applicable or null",
              "sourceSegmentIDs": ["UUID-OF-SEGMENT"]
            }
          ],
          "decisions": [
            {
              "content": "Explicit decision agreed upon",
              "decidedBy": "Speaker name or null",
              "sourceSegmentIDs": ["UUID-OF-SEGMENT"]
            }
          ],
          "actionItems": [
            {
              "title": "Actionable task",
              "owner": "Assignee name or null",
              "deadline": "Due date if mentioned or null",
              "isCompleted": false,
              "sourceSegmentIDs": ["UUID-OF-SEGMENT"]
            }
          ],
          "openQuestions": [
            {
              "question": "Unresolved question",
              "raisedBy": "Speaker name or null",
              "sourceSegmentIDs": ["UUID-OF-SEGMENT"]
            }
          ],
          "quotes": [
            {
              "quote": "Verbatim transcript quote",
              "speaker": "Speaker name",
              "timestamp": 12.5,
              "sourceSegmentID": "UUID-OF-SEGMENT"
            }
          ]
        }
        """
    }
}
