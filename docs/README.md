# Aura — Native macOS AI Meeting Memory & Notetaker

> A native, fast, privacy-first macOS application that captures meeting audio (Microphone + System Audio), provides real-time streaming transcription, lets you jot down shorthand notes, and transforms conversations into trustworthy, source-grounded meeting knowledge.

---

## 🚀 Key Highlights

* **100% Native macOS Experience:** Built exclusively with Swift, SwiftUI, AppKit, and Apple frameworks (`ScreenCaptureKit`, `AVFoundation`, `SwiftData`, `Security`). No Electron, no web wrappers.
* **Invisible Audio Capture:** Captures local microphone input and system/application meeting audio directly from your device using modern macOS APIs. No bot joins your Zoom, Meet, or Teams calls.
* **Human-in-the-Loop AI Synthesis:** Your shorthand notes act as priority anchors for the AI, expanding your key takeaways with full context from the transcript.
* **Source-Linked AI (Zero Hallucination):** Every extracted decision, action item, and quote includes clickable backlinks to the exact timestamped transcript segment.
* **Ephemeral Audio & Radical Privacy:** Audio is processed in volatile memory and purged immediately after transcription. No permanent audio files are stored by default.
* **Local-First Memory & Search:** All meetings, notes, transcripts, and summaries are stored locally with instant full-text search.

---

## 📁 Project Documentation

Explore the comprehensive technical specifications and architecture blueprints:

| Document | Description |
| :--- | :--- |
| 📄 [**PRD.md**](file:///Users/nilkanthdesai/Work/My/Granola/docs/PRD.md) | Product Requirements Document, user journeys, personas, and feature specifications |
| 🏗️ [**ARCHITECTURE.md**](file:///Users/nilkanthdesai/Work/My/Granola/docs/ARCHITECTURE.md) | Technical architecture, audio pipeline, Swift Concurrency, actors, and state machine |
| 🎨 [**DESIGN_SYSTEM.md**](file:///Users/nilkanthdesai/Work/My/Granola/docs/DESIGN_SYSTEM.md) | Native macOS UI/UX design system, typography, colors, layout, and keyboard shortcuts |
| 🔒 [**SECURITY.md**](file:///Users/nilkanthdesai/Work/My/Granola/docs/SECURITY.md) | Privacy-by-design, Keychain integration, zero-retention audio policy, and entitlements |
| 🤖 [**AGENTS.md**](file:///Users/nilkanthdesai/Work/My/Granola/docs/AGENTS.md) | AI system prompts, JSON output schemas, anti-hallucination guardrails, and recipes |
| 📐 [**CODE_STYLE.md**](file:///Users/nilkanthdesai/Work/My/Granola/docs/CODE_STYLE.md) | Swift style guide, actor isolation, SwiftUI decomposition, and error handling rules |
| 🧪 [**TESTING.md**](file:///Users/nilkanthdesai/Work/My/Granola/docs/TESTING.md) | Test strategy, unit test matrix, audio hardware test matrix, and AI evaluation suite |
| 📋 [**Prompt Spec**](file:///Users/nilkanthdesai/Work/My/Granola/docs/macos_ai_meeting_notetaker_ai_coding_prompt.md) | Original master build prompt and engineering instructions |

---

## 🛠️ System Requirements

* **Operating System:** macOS 14.0 (Sonoma) or macOS 15.0+ (Sequoia)
* **Architecture:** Apple Silicon (M1/M2/M3/M4) or Intel Mac
* **Development Environment:** Xcode 15.0+ with Swift 5.9+

---

## 🏗️ Architecture at a Glance

```text
[ Microphone ] ──────> AVAudioEngine ──────┐
                                           │
                                           ▼
                                    [ Audio Mixer ] ───> [ WebSocket STT ] ───> [ Live Transcript ]
                                           ▲                                             │
                                           │                                             │
[ System Audio ] ────> ScreenCaptureKit ───┘                                             ▼
                                                                                [ Human Notes ]
                                                                                         │
                                                                                         ▼
                                                                                [ AI Synthesis ]
                                                                                         │
                                                                                         ▼
                                                                           [ Enhanced Notes & Memory ]
```

---

## 🚦 Roadmap

### Phase 1: MVP (Active Development)
- [x] Technical spike & audio capture architecture
- [ ] Microphone + System Audio mixer with ScreenCaptureKit
- [ ] Real-time WebSocket streaming transcription
- [ ] Three-tier workspace UI (`My Notes` / `Enhanced Notes` / `Transcript`)
- [ ] AI post-processing engine with strict JSON schema & source segment linking
- [ ] SwiftData local storage & SQLite FTS5 full-text search

### Phase 2: Intelligence & Ecosystem
- [ ] EventKit Calendar integration & meeting prep cards
- [ ] Speaker diarization and attendee name mapping
- [ ] Meeting recipes (Engineering, Sales MEDDPICC, 1-on-1, Product Sync)
- [ ] Contextual In-Meeting AI Chat & RAG
- [ ] Native macOS Menu Bar companion app (`MenuBarExtra`)

### Phase 3: Advanced Memory & Local AI
- [ ] Cross-meeting AI chat (Second Brain / Developer Memory)
- [ ] Local Whisper transcription & on-device LLM option
- [ ] Direct export integrations (Linear, Notion, Slack)
