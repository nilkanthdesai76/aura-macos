# AI Agents & Prompts Specification (AGENTS.md)

## Document Purpose
This document defines the prompt engineering architecture, JSON schemas, anti-hallucination guardrails, and coding agent operating rules for the **Native macOS AI Meeting Notetaker** application.

---

## 1. System Prompt Architecture

All LLM prompts in this application must reside in a centralized, version-controlled repository (`AI/PromptManager.swift`). No prompt strings should be scattered across views or ViewModels.

### 1.1 Core Synthesis System Prompt (Version 1.0)

```text
You are an expert meeting intelligence engine. Your task is to transform a raw meeting transcript and human-typed shorthand notes into structured, executive-ready meeting documentation.

# CORE RULES & ANTI-HALLUCINATION CONSTRAINTS
1. STRICT GROUNDING: Extract information ONLY from the provided transcript and user notes.
2. NEVER INVENT: Never fabricate decisions, commitments, action items, dates, names, or quotes.
3. PRESERVE UNCERTAINTY: If a discussion was inconclusive, explicitly state that no consensus was reached.
4. HUMAN-IN-THE-LOOP PRIORITY: Treat the user's raw notes as primary attention anchors. If the user jotted down "Pricing concern", locate that discussion in the transcript and expand it thoroughly.
5. SOURCE LINKING: Every extracted Action Item and Decision MUST include the exact `sourceSegmentIDs` (UUIDs of the transcript segments from which they were derived).
6. EXACT QUOTES ONLY: Important quotes must be verbatim excerpts from the transcript. Do not paraphrase inside quotation fields.
7. STRICT STRUCTURE: Output valid JSON matching the exact schema specified below. Do not wrap in conversational preamble.
```

---

## 2. Structured JSON Output Schema

The LLM must return a structured JSON response matching the following Swift Decodable contract:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "MeetingAnalysisResult",
  "type": "object",
  "properties": {
    "summary": {
      "type": "string",
      "description": "A crisp, 2-3 paragraph executive summary of the meeting."
    },
    "discussionPoints": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "topic": { "type": "string" },
          "details": { "type": "string" },
          "userNoteAnchor": { "type": "string", "nullable": true },
          "sourceSegmentIDs": { "type": "array", "items": { "type": "string", "format": "uuid" } }
        },
        "required": ["topic", "details", "sourceSegmentIDs"]
      }
    },
    "decisions": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "id": { "type": "string", "format": "uuid" },
          "content": { "type": "string" },
          "decidedBy": { "type": "string", "nullable": true },
          "sourceSegmentIDs": { "type": "array", "items": { "type": "string", "format": "uuid" } }
        },
        "required": ["id", "content", "sourceSegmentIDs"]
      }
    },
    "actionItems": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "id": { "type": "string", "format": "uuid" },
          "title": { "type": "string" },
          "owner": { "type": "string", "nullable": true },
          "deadline": { "type": "string", "nullable": true },
          "status": { "type": "string", "enum": ["pending", "in_progress", "completed"] },
          "sourceSegmentIDs": { "type": "array", "items": { "type": "string", "format": "uuid" } }
        },
        "required": ["id", "title", "sourceSegmentIDs"]
      }
    },
    "openQuestions": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "question": { "type": "string" },
          "raisedBy": { "type": "string", "nullable": true },
          "sourceSegmentIDs": { "type": "array", "items": { "type": "string", "format": "uuid" } }
        },
        "required": ["question", "sourceSegmentIDs"]
      }
    },
    "importantQuotes": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "quote": { "type": "string" },
          "speaker": { "type": "string" },
          "timestamp": { "type": "number" },
          "sourceSegmentID": { "type": "string", "format": "uuid" }
        },
        "required": ["quote", "speaker", "sourceSegmentID"]
      }
    }
  },
  "required": ["summary", "discussionPoints", "decisions", "actionItems", "openQuestions", "importantQuotes"]
}
```

---

## 3. Meeting Recipes / Template Prompts

### 3.1 Engineering Meeting Recipe
* **System Focus:** Emphasize technical debt, architectural tradeoffs, API contract changes, security considerations, and deployment dependencies.
* **Extraction Fields:**
  * Architecture Decisions (with rationale and alternatives rejected)
  * Technical Risks & Blockers
  * API / Schema Changes
  * Action Items with Engineer assignments

### 3.2 Sales & Customer Discovery Recipe (MEDDPICC)
* **System Focus:** Uncover customer pain points, current software stack, budget availability, decision-making chain, and specific objections.
* **Extraction Fields:**
  * Metrics & Business Pain
  * Economic Buyer & Decision Criteria
  * Timeline & Budget Signals
  * Competitors Mentioned
  * Agreed Next Steps

### 3.3 1-on-1 Catchup Recipe
* **System Focus:** Interpersonal dynamics, feedback given/received, career goals, personal wellbeing, and blockers.
* **Extraction Fields:**
  * Key Themes & Highlights
  * Blockers to Remove
  * Commitments & Follow-ups for Next 1:1

---

## 4. In-Meeting & Cross-Meeting Chat Agent (RAG)

### 4.1 In-Meeting Chat Protocol
* **Context Assembly:** Ingests only the current meeting's raw notes, transcript segments, and metadata.
* **Prompt Instructions:**
  ```text
  You are answering questions about the current meeting.
  Answer using ONLY the provided transcript segments.
  For every claim made in your response, cite the exact timestamp or segment number: [Segment #ID, 04:12].
  If the question asks about something not discussed in the meeting, respond: "This was not discussed during the meeting."
  ```

### 4.2 Cross-Meeting Intelligence (Second Brain)
* **Query Pipeline:**
  1. Analyze user query $\rightarrow$ Extract entities, date filters, keywords.
  2. Perform hybrid retrieval (SQLite FTS5 + Vector Embeddings).
  3. Re-rank top $K$ meeting transcript chunks.
  4. Inject retrieved chunks into context with meeting titles and dates.
  5. Generate grounded response with multi-meeting citations.

---

## 5. Coding Agent Guidelines for Developers & AI Assistants

When developing, refactoring, or extending this codebase:

1. **Strict Actor Isolation:** Never perform network I/O, audio buffer processing, or AI parsing on the main thread.
2. **Never Mock Success Silently:** If an API key is missing or audio permissions are denied, explicitly throw typed errors and render clear native macOS UI error sheets.
3. **No Third-Party Bloat:** Use Apple's first-party frameworks (`ScreenCaptureKit`, `AVFoundation`, `SwiftData`, `Security`, `OSLog`) whenever possible.
4. **Prompt Immutability:** Never hardcode inline prompt strings in View files. Always add prompts to `PromptManager`.
5. **Deterministic Testing:** Write unit tests for JSON parsing recovery, transcript merging, and segment linking using mock JSON fixtures.
