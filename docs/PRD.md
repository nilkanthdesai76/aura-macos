# Product Requirements Document (PRD)

## Project Name: Aura / Native macOS AI Meeting Memory
**Document Version:** 1.0.0  
**Target Platform:** macOS 14.0+ (Sonoma & Sequoia)  
**Status:** Approved for Engineering

---

## 1. Product Overview

### 1.1 Mission Statement
To build a native macOS AI meeting intelligence application that silently operates during meetings, capturing both microphone and system audio without invasive bot participants. The app bridges real-time conversation transcription with human-typed context, synthesizing accurate, source-grounded meeting records, action items, and cross-meeting memory.

### 1.2 Core Value Proposition
1. **Invisible Capture:** Operates purely on-device via native macOS audio capture APIs (`ScreenCaptureKit` / `AVFoundation`). No third-party bots appear in Zoom, Google Meet, or Microsoft Teams.
2. **Human + AI Symbiosis:** Leverages the user's manual shorthand notes as priority anchors to guide the AI synthesis, ensuring summaries reflect what the user actually cares about.
3. **Ground-Truth & Source Linking:** Every extracted action item, decision, and quote is bi-directionally linked to the exact timestamped transcript segment to eliminate hallucination risk.
4. **Privacy-by-Design:** Audio buffers are transcribed ephemerally and purged immediately. Zero audio is stored unless explicitly opted-in.
5. **Native macOS Excellence:** Built exclusively with Swift, SwiftUI, and modern macOS design paradigms (Command Palette, Menu Bar helper, keyboard shortcuts, low CPU overhead).

---

## 2. Target Personas & Use Cases

| Persona | Key Needs | Primary Use Case |
| :--- | :--- | :--- |
| **Founders & Executives** | High-level synthesis, investor & board meeting recall, explicit decision tracking | Quick bullet notes during high-stakes calls; instant executive summaries and follow-ups. |
| **Product Managers & Designers** | User feedback capture, feature discovery, alignment checks | Customer interview synthesis, feature requirement extraction with verbatim quotes. |
| **Software Engineers & Architects** | Architecture decision tracking, technical blockers, API changes | Engineering syncs, tracking technical debt discussions, searching "Why did we choose X?". |
| **Sales & Account Executives** | Action item ownership, customer objections, budget/timeline signals | Customer discovery calls, MEDDPICC/BANT structured summaries, CRM-ready action points. |

---

## 3. Product Workflows & User Journeys

### 3.1 Pre-Meeting Workflow
1. User sees upcoming calendar meetings in the Home view or Menu Bar item.
2. User clicks **"Start Meeting"** (or hits global shortcut `⌥⌘M` / `⌘Enter`).
3. User chooses or defaults to a template/recipe (e.g., *Engineering Sync*, *1:1*, *Sales Discovery*).
4. System verifies microphone and system audio capture permissions.

### 3.2 In-Meeting Workflow (Live Session)
1. Split-pane interface opens:
   * **Left:** Fast Markdown Notepad for user's shorthand notes.
   * **Right:** Streaming, diarized, timestamped real-time transcript.
2. Subtle, low-overhead level meter displays active audio input (Mic & System audio).
3. User types shorthand notes (e.g., *"Database migration timeline"*).
4. Audio buffers are streamed to the transcription provider in real-time.

### 3.3 Post-Meeting Workflow (Synthesis & Review)
1. User clicks **"Stop Meeting"**.
2. Audio stream halts; temporary audio buffers are deleted from memory.
3. Post-processing pipeline executes asynchronously:
   * Combines user notes + full transcript + meeting metadata.
   * AI synthesizes structured JSON (Summary, Key Decisions, Action Items, Open Questions, Quotes).
   * Generates source-segment backlinks for every decision and action item.
4. User reviews the **Enhanced Notes** tab, edits if needed, and checks source quotes.
5. Notes and transcript are saved to local database (SwiftData) and indexed for instant search.

### 3.4 Post-Meeting Intelligence & Chat
1. **In-Meeting Chat:** User asks questions specific to the meeting (e.g., *"What were John's objections to the timeline?"*). Answers return with direct source citations.
2. **Cross-Meeting Search / Second Brain:** User searches keywords or asks global queries (e.g., *"What did we decide about auth in September?"*).

---

## 4. Detailed Feature Specifications

### 4.1 Audio Capture & Management
* **FR-AUD-01:** Capture local microphone audio via `AVAudioEngine` / `AVCaptureDevice`.
* **FR-AUD-02:** Capture system/application audio via `ScreenCaptureKit` (macOS 13.0+) without requiring third-party virtual audio kexts.
* **FR-AUD-03:** Live Audio Mixer normalizing sample rates (target 16kHz mono PCM) and handling gain balance.
* **FR-AUD-04:** Graceful audio device switching (Bluetooth connect/disconnect, headset change, system sleep/wake) without crashing or dropping state.
* **FR-AUD-05:** Lightweight amplitude level meter for visual confirmation of capture.

### 4.2 Streaming Transcription & Diarization
* **FR-TRA-01:** Real-time speech-to-text streaming via WebSocket/gRPC using a pluggable `TranscriptionProvider` protocol.
* **FR-TRA-02:** Support partial (interim) and final transcript segments with stable segment UUIDs.
* **FR-TRA-03:** Speaker diarization labeling (`Speaker 1`, `Speaker 2`) with candidate matching to calendar attendees and manual rename capability.
* **FR-TRA-04:** Network drop recovery with exponential backoff and seamless session resumption without duplicate segments.

### 4.3 Workspace & Note Taking
* **FR-NOT-01:** Real-time, fast Markdown editor for user notes with slash commands (`/`) for fast formatting.
* **FR-NOT-02:** Three-tier view toggle: **My Notes** (raw), **Enhanced** (AI structured), **Transcript** (timestamped stream).
* **FR-NOT-03:** Autosave on every keystroke to prevent data loss.

### 4.4 AI Synthesis & Enhancement
* **FR-AI-01:** LLM orchestration via `AIProvider` protocol (OpenAI, Anthropic Claude, Gemini, Local models).
* **FR-AI-02:** Strict JSON schema validation for all outputs (Summary, Decisions, Action Items, Quotes, Questions).
* **FR-AI-03:** Source-grounding constraint: Action items and decisions must map to `sourceSegmentIDs`.
* **FR-AI-04:** Configurable Meeting Recipes (1:1, Product Planning, Engineering Sync, Sales Discovery).
* **FR-AI-05:** In-meeting RAG/Chat enabling targeted question answering based on meeting context.

### 4.5 Local Storage, Search & Indexing
* **FR-DAT-01:** Offline-first architecture using SwiftData / SQLite for zero cloud dependency on storage.
* **FR-DAT-02:** Local Full-Text Search (FTS) indexing across meeting titles, notes, transcripts, decisions, and action items.
* **FR-DAT-03:** Semantic vector embeddings (Phase 2) for conceptual search across historical meetings.

### 4.6 Native macOS Integrations & UI
* **FR-MAC-01:** Menu Bar companion app with upcoming meeting status and 1-click capture.
* **FR-MAC-02:** Global Command Palette (`⌘K`) for searching, switching views, and running actions.
* **FR-MAC-03:** Native macOS keyboard shortcuts (`⌘Enter`, `⌘F`, `⌘1`, `⌘2`, `⌘3`).
* **FR-MAC-04:** Full dark/light mode and system appearance adherence.

---

## 5. Non-Functional Requirements (NFRs)

* **NFR-PERF-01 (UI Fluidity):** 60 FPS scrolling and zero main-thread hitching during active audio capture and transcription.
* **NFR-PERF-02 (Memory Bounds):** Memory footprint must remain under 150MB during active recording sessions up to 3 hours.
* **NFR-PERF-03 (CPU Overhead):** Background audio mixing and rendering CPU usage must stay below 5% on Apple Silicon.
* **NFR-SEC-01 (Zero Audio Retention):** Raw audio buffers must be purged from memory immediately upon transcription completion.
* **NFR-SEC-02 (Credential Isolation):** All API tokens, OAuth keys, and secrets must be stored strictly in the macOS Keychain.
* **NFR-REL-01 (Offline Resilience):** App must fully function offline for note-taking, local search, and reviewing past meetings.

---

## 6. Release Phases & Roadmap

```
┌─────────────────────────┐     ┌─────────────────────────┐     ┌─────────────────────────┐
│        PHASE 1          │     │        PHASE 2          │     │        PHASE 3          │
│         (MVP)           │     │   (Team & Deep AI)      │     │  (Ecosystem & Local)    │
├─────────────────────────┤     ├─────────────────────────┤     ├─────────────────────────┤
│ • Native SwiftUI Shell  │     │ • Calendar Integration  │     │ • Local On-Device LLM   │
│ • Mic + System Audio    │     │ • Speaker Diarization   │     │ • Local Whisper STT     │
│ • Audio Mixer & Levels  │     │ • Meeting Recipes       │     │ • Linear/Notion Exports │
│ • Cloud STT Streaming   │     │ • In-Meeting AI Chat    │     │ • MCP Server Extension  │
│ • Live Transcript UI    │     │ • Semantic Search (RAG) │     │ • Multi-turn Cross-Chat │
│ • User Notes Editor     │     │ • Menu Bar Companion    │     │ • Cloud Sync / Teams    │
│ • AI Summary & Decisions│     │ • Global Hotkey (⌥⌘M)   │     │ • Multilingual Support  │
│ • Local SwiftData Store │     │                         │     │                         │
│ • Full-Text Search      │     │                         │     │                         │
└─────────────────────────┘     └─────────────────────────┘     └─────────────────────────┘
```
