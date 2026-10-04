# Granola Reference App Feature & Knowledge Base Specification

> **Document Type:** Reference Product & Technical Knowledge Base  
> **Target Subject:** Granola AI Meeting Notepad ([granola.ai](https://granola.ai))  
> **Purpose:** Comprehensive analysis of product architecture, UX flows, feature sets, technical design, AI pipeline, and competitive differentiators for building or integrating with meeting intelligence applications.

---

## 1. Executive Summary & Product Philosophy

**Granola** is an AI-first meeting notepad designed for professionals (founders, product managers, engineers, investors, sales reps, and researchers). Unlike conventional meeting bots (e.g., Otter.ai, Fireflies.ai, Fathom) that join video calls as visible bot participants (e.g., "Granola's Notetaker"), Granola operates as a **native desktop application (macOS/Windows) and companion mobile app** that captures audio directly from the user's device (combining microphone input and system speaker loopback).

### Core Philosophy: Human-in-the-Loop AI
* **Not Just Passive Transcription:** Traditional tools generate generic, verbose transcripts and AI summaries that often miss the user's personal perspective or focus points.
* **Symbiotic Note-Taking:** Granola combines **user-typed shorthand/intent** with **raw audio transcript context** to produce structured, highly contextual, and actionable notes.
* **Invisible & Non-Intrusive:** No awkward bot joining calls, no permissions needed from meeting hosts, and no recording banner anxiety for participants.
* **Ephemeral Audio:** Audio recordings are transcribed in near real-time and deleted immediately after processing, prioritizing user privacy and data minimization.

---

## 2. High-Level Architecture & Ecosystem

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                             CLIENT LAYER (macOS / Desktop)                  │
├────────────────────────┬───────────────────────────┬────────────────────────┤
│     Audio Capture      │       Native UI/UX        │     Calendar Sync      │
│  - ScreenCaptureKit    │  - SwiftUI / AppKit       │  - Google Calendar API │
│  - CoreAudio Tap       │  - Rich Text / Markdown   │  - MS Graph (Outlook)  │
│  - Mic + System Audio  │  - Command Palette (⌘K)   │  - Real-time detector  │
└───────────┬────────────┴─────────────┬─────────────┴───────────┬────────────┘
            │                          │                         │
            ▼                          ▼                         ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                            PROCESSING & SYNC ENGINE                         │
├─────────────────────────────────────────────────────────────────────────────┤
│  1. Audio Stream Segmentation & Noise Suppression                           │
│  2. Local Cache & Optimistic UI State Management (SQLite / CoreData)        │
│  3. Multi-turn AI Chat Context Assembler                                    │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                            BACKEND & AI SERVICES                            │
├────────────────────────┬───────────────────────────┬────────────────────────┤
│  Transcription Engine  │     AI Synthesis LLM      │     Storage & Auth     │
│  - Whisper / Deepgram  │  - Claude 3.5 Sonnet      │  - Supabase / Postgres │
│  - Speaker Diarization │  - GPT-4o                 │  - Vector Embeddings   │
│  - Word-level Timings  │  - Custom Prompt Pipeline │  - SOC2 Compliant Enc. │
└────────────────────────┴───────────────────────────┴────────────────────────┘
```

---

## 3. Core Product Features Breakdown

### 3.1. Bot-Free Audio Capture Engine
* **Dual-Channel Audio Tap:**
  * **Input (Microphone):** Captures the user's voice with hardware echo cancellation.
  * **Output (System Audio Loopback):** Captures other participants through macOS `ScreenCaptureKit` or CoreAudio process taps (Zoom, Google Meet, Microsoft Teams, Slack Huddles, Webex, Loom, Phone Calls).
* **Zero Host Permission Required:** Works on any call without requiring meeting host approval or calendar invite forwards.
* **Auto Meeting Detection:** Detects ongoing calls or calendar triggers to prompt "Start Recording" or automatically initiate capture.
* **Ad-Hoc / In-Person Audio:** Supports in-person meetings, voice memos, and mobile/Apple Watch capture.

---

### 3.2. Three-Tier Note Workspace (The Core UI Paradigm)

When viewing any meeting in Granola, the workspace is organized into a clean 3-tab/split layout:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ [← Back]  Team Weekly Sync — Sept 29, 2026        [ Share ] [ Export ] [ ⋯ ]│
├───────────────────────────────────┬─────────────────────────────────────────┤
│  [ My Notes ] [ Enhanced* ] [ Transcripts ]                                 │
├───────────────────────────────────┴─────────────────────────────────────────┤
│                                                                             │
│  ## Key Decisions                                                           │
│  - Decided to migrate to SwiftUI macOS native client for v2.0               │
│  - Launch timeline confirmed for Oct 15                                     │
│                                                                             │
│  ## Action Items                                                            │
│  - [ ] @Nilkanth: Finalize API endpoints for transcription sync             │
│  - [ ] @Sarah: Update linear tickets for design handoff                     │
│                                                                             │
│  ## Discussion Points                                                       │
│  ...                                                                        │
│                                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│ 🪄 Ask Granola: [ Draft a follow-up email to the team...                  ] │
└─────────────────────────────────────────────────────────────────────────────┘
```

1. **"My Notes" (Raw Notepad):**
   * Minimalist, distraction-free markdown text editor.
   * Auto-saves user keystrokes in real-time while the meeting is in progress.
   * Supports bullet lists, checklists, markdown headers, bold/italic, slash commands (`/`).
   * Acts as the *primary semantic anchor* for the AI.

2. **"Enhanced Notes" (AI-Synthesized Output):**
   * The signature feature of Granola.
   * Combines the user's shorthand notes with the full conversation transcript.
   * Fills in missed details, clarifies ambiguities, extracts structured action items, metrics, and key decisions.
   * Never overrides or erases the user's original notes—allows toggling between raw and enhanced views.
   * Supports one-click re-enhancement with different templates/prompts.

3. **"Transcript" (Full Conversation Record):**
   * Full chronological, diarized transcript with timestamps and speaker tags.
   * Searchable with instant highlight and filter.
   * Clickable timestamp jumps and copyable snippet quotes.

---

### 3.3. Custom Templates & AI Recipes
Granola allows users to define how the AI structures the post-meeting synthesis.

* **Built-in Standard Templates:**
  * **1-on-1 Catchup:** Wins, challenges, feedback, career goals, personal updates, agreed next steps.
  * **Customer Discovery / User Interview:** User profile, pain points, current workflow, feature requests, willingness to pay, exact quotes.
  * **Sales Discovery (MEDDPICC / BANT):** Budget, authority, need, timeline, decision criteria, competitors, next steps.
  * **Engineering Standup / Tech Spec Review:** Technical decisions, blockers, architectural tradeoffs, action items.
  * **Executive / Board Meeting:** Strategic alignment, financial metrics, risks, executive approvals.
  * **General Meeting:** Quick summary, key takeaways, action items by owner.
* **Custom Template Builder:**
  * Define custom Markdown structure headers.
  * Custom prompt instructions (e.g., *"Focus heavily on numbers, deadlines, and direct quotes"* or *"Format in bullet points with emoji indicators"*).
  * Assign default templates per calendar event keyword or meeting type.

---

### 3.4. "Ask Granola" (Meeting & Cross-Meeting AI Chat)
* **In-Meeting Contextual Chat:**
  * Side panel / bottom bar prompt input.
  * Pre-built quick action chips:
    * *"Draft a thank you email to attendees"*
    * *"List all questions that remained unanswered"*
    * *"Extract all numerical metrics and dates discussed"*
    * *"What pushback did the client have regarding pricing?"*
* **Cross-Meeting Global Search & Chat (Second Brain):**
  * Ask questions across all historical meetings: *"What was our agreed budget for Q4 marketing across all August meetings?"* or *"When did Sarah mention her vacation dates?"*
  * Vector embeddings and semantic retrieval across past transcripts and notes.

---

### 3.5. Calendar Integration & Proactive Workflow
* **Calendar Sync:** Two-way integration with Google Calendar and Microsoft Outlook / Office 365.
* **Meeting Preparation Card:** Pre-populates attendee names, meeting subject, agenda, and previous meeting notes with the same participants.
* **Upcoming Meeting Widget / Menu Bar:**
  * macOS status bar icon showing time until next meeting.
  * One-click "Join Call & Take Notes" button.

---

### 3.6. Sharing, Collaboration & Integrations
* **Interactive Web Sharing:**
  * Public or restricted web link (`granola.ai/n/...`).
  * Clean web viewer allowing teammates to read enhanced notes, search the transcript, or copy action items.
* **Export & Integrations:**
  * **Notion:** Direct sync to a Notion database with custom property mappings.
  * **Slack:** One-click share formatted summary to a specific Slack channel or DM.
  * **Linear / Jira:** Create task tickets directly from parsed action items.
  * **HubSpot / Salesforce:** Log meeting notes to contacts, companies, or deals.
  * **Copy to Clipboard:** Formatted rich text, clean Markdown, or raw text.

---

### 3.7. Security, Privacy & Data Retention
* **Zero Audio Retention Policy:** Audio data is converted to text via secure streaming and immediately purged from local/remote memory.
* **No Meeting Bot Footprint:** Avoids recording compliance friction in states/jurisdictions requiring participant awareness when standard audio capture guidelines apply.
* **Enterprise Grade:** SOC 2 Type II certified, TLS 1.3 in transit, AES-256 at rest, GDPR/CCPA compliant.
* **Zero Model Training on Customer Data:** Strict agreements preventing third-party LLM providers from training foundation models on user transcripts or notes.

---

## 4. UI/UX Design Language & Interaction Patterns

1. **Aesthetic:** Minimalist, editorial typography (modern serif/sans pairings), calm monochromatic palette, high contrast, distraction-free.
2. **Speed & Latency:** Instant startup, zero lag typing, optimistic UI updates, sub-second transcript search.
3. **Keyboard First:**
   * `⌘ + K`: Global Command Palette (search meetings, templates, actions).
   * `⌘ + N`: New Quick Note / Ad-hoc meeting.
   * `⌘ + E`: Toggle between My Notes and Enhanced Notes.
   * `⌘ + Shift + T`: Toggle Transcript view.
   * `/`: Slash command menu inside editor (Insert template, Heading, Checklist, Bullet list, Timestamp).
4. **macOS Native Feel:** Menu bar integration, system dark mode support, fluid SwiftUI/AppKit animations, native system audio taps.

---

## 5. Technical Requirements for Building a Granola Alternative / Clone

| Component | Recommended Technology / Approach |
| :--- | :--- |
| **Desktop Framework** | macOS Native (Swift / SwiftUI + AppKit) or Electron / Tauri |
| **System Audio Capture** | macOS `ScreenCaptureKit` API (macOS 12.3+) + `AVAudioEngine` for microphone input |
| **Audio Mixing & Processing**| CoreAudio 2-channel mixer (Left = Mic / Right = System, or merged 16kHz mono PCM stream) |
| **Speech-to-Text (STT)** | Deepgram Nova-2 / OpenAI Whisper / AssemblyAI (with real-time streaming WebSockets & speaker diarization) |
| **LLM Orchestration** | Anthropic Claude 3.5 Sonnet / OpenAI GPT-4o with structured JSON outputs |
| **Editor Component** | Custom NSTextView / SwiftUI TextEditor or Prosemirror / TipTap (if web/Electron) |
| **Local Database** | SQLite (via GRDB.swift) or CoreData for offline storage and local full-text search (FTS5) |
| **Cloud Sync & Auth** | Supabase (PostgreSQL, Row Level Security, Auth, Edge Functions, Vector pgvector) |
| **Calendar Sync** | Google Calendar API + Microsoft Graph API with webhook subscriptions |

---

## 6. Granola vs. Traditional Meeting Notetakers

| Feature | Granola | Otter.ai / Fireflies / Fathom |
| :--- | :--- | :--- |
| **Capture Method** | Native Device Audio (Mic + System Output) | Meeting Bot joins as a participant |
| **Bot in Participant List** | ❌ No (100% Invisible) | ✅ Yes (Bot tile in Zoom/Meet/Teams) |
| **User Note Synergy** | 🌟 AI enhances user's typed notes + transcript | ❌ Transcribes everything equally, ignoring user's focus |
| **Audio Storage** | Purged immediately post-transcription | Stored indefinitely on cloud servers |
| **Desktop Notepad Feel** | Fast, minimalist native editor | Web-first recording portal / dashboard |
| **Custom Prompt Templates**| Highly customizable AI transformation recipes | Fixed standard summary formats |
| **Offline Functionality** | Take notes offline, sync & transcribe when reconnected | Requires active internet & bot connection |

---

## 7. Knowledge Base Summary & Actionable Takeaways for Development

1. **Build around the User's Active Attention:** The killer value proposition of Granola is not automated transcription alone; it is empowering the user to write 5-10 quick bullet points and having AI turn those raw thoughts into an executive-ready document backed by exact transcript quotes.
2. **Audio Pipeline Reliability:** Clean system audio loopback via `ScreenCaptureKit` without installing virtual kernel extensions (kexts) is the key technical enabler on macOS.
3. **Prompt Engineering Strategy:** The synthesis prompt requires two inputs:
   * `user_raw_notes`: The user's typed notes during the call.
   * `full_transcript`: The diarized timestamped transcript.
   * Prompt instruction: *"Treat user_raw_notes as the hierarchy of importance. Expand upon the user's bullet points using facts, decisions, and quotes from full_transcript. Keep the tone concise, professional, and structured."*
