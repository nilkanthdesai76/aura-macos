# Technical Architecture Specification

## Target Platform: macOS 14.0+ (Sonoma / Sequoia)
**Language:** Swift 5.9 / Swift 6  
**UI Framework:** SwiftUI + AppKit integration  
**Concurrency Model:** Modern Swift Concurrency (Actors, Async/Await, TaskGroups, AsyncStreams)

---

## 1. System Architecture Overview

The application follows a **Modular Clean Architecture** with strict isolation between the hardware audio layer, real-time networking/transcription, AI synthesis engine, local persistence, and the presentation layer.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            PRESENTATION LAYER (SwiftUI)                     │
│  NavigationSplitView │ Toolbar │ CommandPalette (⌘K) │ MenuBarController    │
│  @MainActor ViewModels (HomeViewModel, LiveMeetingViewModel, SearchViewModel)│
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │ Observes / Invokes
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         SESSION & COORDINATION LAYER                        │
│  MeetingSessionCoordinator (Coordinates Audio + Transcript + AI Lifecycle)   │
│  AppState & DependencyContainer (Service Locator / Dependency Injection)     │
└──────────────┬───────────────────────┬────────────────────────┬─────────────┘
               │                       │                        │
               ▼                       ▼                        ▼
┌───────────────────────┐  ┌───────────────────────┐  ┌───────────────────────┐
│     AUDIO LAYER       │  │  TRANSCRIPTION LAYER  │  │       AI LAYER        │
│  actor AudioCapture   │  │  actor Transcriber    │  │  actor AIService      │
│  - MicrophoneCapture  │  │  - CloudWebSocketSTT  │  │  - NoteEnhancer       │
│  - SystemAudioCapture │  │  - LocalSpeechSTT     │  │  - SummaryGenerator   │
│  - AudioMixer (16kHz) │  │  - DiarizationEngine  │  │  - ActionExtractor    │
│  - LevelMeterStream   │  │  - TranscriptStore    │  │  - InMeetingRAGChat   │
└──────────────┬────────┘  └───────────┬───────────┘  └───────────┬───────────┘
               │                       │                          │
               └───────────────────────┼──────────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                             DATA & STORAGE LAYER                            │
│  SwiftData ModelContainer │ SQLite FTS5 Search │ Keychain Credentials       │
│  MeetingRepository │ TranscriptRepository │ RecipeRepository                │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Directory & Module Structure

```text
MeetingAI/
│
├── App/
│   ├── MeetingAIApp.swift             # App entry point, WindowGroup & MenuBarExtra
│   ├── AppState.swift                 # Global application state (Navigation, ActiveSession)
│   ├── AppCoordinator.swift           # High-level navigation and deep link coordinator
│   └── DependencyContainer.swift      # Thread-safe DI container for all singletons/actors
│
├── Features/
│   ├── Home/                          # Dashboard, upcoming meetings, quick capture
│   ├── LiveMeeting/                   # Split-pane live recording & note taking interface
│   ├── Meetings/                      # Meeting history, detail view, tabs (Notes/Enhanced/Transcript)
│   ├── Notes/                         # Markdown editor component, slash command engine
│   ├── Transcript/                    # Diarized streaming transcript viewer with search
│   ├── AIChat/                        # Contextual in-meeting & cross-meeting AI chat
│   ├── Search/                        # Full-text & semantic search interfaces
│   └── Settings/                      # Audio device selection, API keys, AI model config
│
├── Audio/
│   ├── AudioCaptureManager.swift      # Actor orchestrating Mic + System capture streams
│   ├── MicrophoneCapture.swift        # AVAudioEngine capture with sample rate conversion
│   ├── SystemAudioCapture.swift       # ScreenCaptureKit SCStream audio loopback capture
│   ├── AudioMixer.swift               # Dual-channel audio buffer normalizer & mixer
│   ├── AudioDeviceManager.swift       # CoreAudio device discovery and hot-plug listener
│   ├── AudioBufferProcessor.swift     # Ring buffer, format converter (to 16kHz mono PCM)
│   └── AudioPermissionManager.swift   # Microphone and Screen Recording permission handler
│
├── Transcription/
│   ├── TranscriptionProvider.swift    # Protocol for streaming STT engines
│   ├── CloudTranscriptionProvider.swift # WebSocket streaming provider (Deepgram / Whisper)
│   ├── LocalTranscriptionProvider.swift # SFSpeechRecognizer / Local Whisper provider
│   ├── StreamingTranscriber.swift     # Segment stability, interim/final state manager
│   ├── TranscriptSegment.swift        # Transcript data model with speaker and timestamps
│   └── SpeakerManager.swift           # Diarization speaker mapping and alias management
│
├── AI/
│   ├── AIProvider.swift               # Pluggable LLM interface (Claude, OpenAI, Gemini)
│   ├── AIService.swift                # Structured generation orchestrator with retry policy
│   ├── NoteEnhancer.swift             # Human-in-the-loop synthesis algorithm
│   ├── SummaryGenerator.swift         # Structured summary & discussion points builder
│   ├── ActionItemExtractor.swift      # Action item parser with sourceSegmentIDs
│   ├── DecisionExtractor.swift        # Decision parser with transcript backlink references
│   ├── RecipeEngine.swift             # Meeting template selector and prompt compiler
│   ├── RAGService.swift               # Semantic chunking and retrieval engine
│   └── PromptManager.swift            # Centralized, version-controlled system prompts
│
├── Data/
│   ├── Models/                        # SwiftData @Model entities
│   │   ├── Meeting.swift
│   │   ├── Participant.swift
│   │   ├── TranscriptSegmentEntity.swift
│   │   ├── UserNoteEntity.swift
│   │   └── MeetingSummaryEntity.swift
│   ├── Repositories/                  # Data access protocols and SwiftData implementations
│   └── Persistence/                   # ModelContainer setup, schema migrations, seed data
│
├── Search/
│   ├── FullTextSearch.swift           # SQLite FTS5 engine for fast local keyword queries
│   ├── SemanticSearch.swift           # Vector embedding and cosine similarity search
│   └── SearchService.swift            # Unified search coordinator combining FTS & semantic
│
├── Calendar/
│   ├── CalendarManager.swift          # EventKit calendar sync and upcoming meeting listener
│   └── MeetingEventMapper.swift       # Mapping EKEvent to Meeting metadata and attendees
│
├── Security/
│   ├── KeychainManager.swift          # Secure storage for API tokens and credentials
│   ├── PrivacyManager.swift           # Zero-retention audio purging enforcement
│   └── PermissionManager.swift        # Centralized system permission coordinator
│
└── Utilities/
    ├── Logger.swift                   # Structured OSLog wrapper (no sensitive data)
    ├── Extensions/                    # Swift and SwiftUI extension helpers
    └── DesignSystem/                  # Typography, colors, badges, and shared UI atoms
```

---

## 3. Concurrency Model & Actor Isolation Boundaries

To guarantee a **strict 60 FPS UI** and eliminate race conditions, the architecture enforces clear isolation domains:

```
┌────────────────────────────────────────────────────────┐
│               @MainActor Domain                        │
│  - SwiftUI Views                                       │
│  - Observable ViewModels (LiveMeetingViewModel, etc.)  │
│  - AppState & Navigation                               │
└───────────────────────────▲────────────────────────────┘
                            │ AsyncStream / Task
┌───────────────────────────┴────────────────────────────┐
│                  Actor Isolated Engines                │
│                                                        │
│  actor AudioCaptureManager                             │
│    • Real-time audio buffer ingestion & mixing         │
│    • Level meter calculation (publishes AsyncStream)   │
│                                                        │
│  actor StreamingTranscriber                            │
│    • WebSocket stream handling                         │
│    • Stable segment ID assignment & partial debounce   │
│                                                        │
│  actor AIService                                       │
│    • Network requests to LLMs                          │
│    • JSON validation and retry engine                  │
│                                                        │
│  actor MeetingRepository                               │
│    • Background SwiftData operations & SQLite queries  │
└────────────────────────────────────────────────────────┘
```

* **No Blocking on Main Thread:** Audio conversion, WebSocket transmission, database writes, and LLM parsing are executed inside background actors.
* **Stream-Based UI Updates:** Audio level meters and streaming transcripts publish `AsyncStream<T>` pipelines consumed by `@MainActor` ViewModels.

---

## 4. Audio Capture & Processing Pipeline

The audio subsystem captures two independent audio streams and downmixes them into a standard **16kHz, 16-bit Mono PCM** buffer stream.

```text
[Input 1: Microphone] ─────> AVAudioEngine (InputNode) ───┐
                                                          │
                                                          ▼
                                                  [ Audio Mixer ]
                                                  - Format converter
                                                  - Level normalizer
                                                  - Echo suppression
                                                          ▲
                                                          │
[Input 2: System Audio] ───> ScreenCaptureKit (SCStream) ─┘
                                                          │
                                                          ▼
                                                  [ 16kHz Mono PCM ]
                                                          │
                                                          ▼
                                                  [ WebSocket STT ]
```

### 4.1 Capture Mechanisms
1. **Microphone Capture:** Uses `AVAudioEngine` attached to the user's selected input hardware device.
2. **System Audio Capture:** Uses `ScreenCaptureKit` (`SCStreamConfiguration.capturesAudio = true`, `excludesCurrentProcessAudio = true`). Captures audio from all system processes (Zoom, Google Meet, Slack, Teams) without installing third-party kernel extensions.
3. **Format Normalization:** Standardizes disparate hardware sample rates (e.g. 48kHz, 44.1kHz) into 16kHz mono PCM using `AVAudioConverter`.
4. **Ephemeral Buffer Lifecycle:** Raw audio buffers are held in a circular ring buffer only long enough to be converted and streamed via WebSocket. The buffer is immediately zeroed and released.

---

## 5. Core Meeting State Machine

The meeting lifecycle is governed by an explicit state machine managed by `MeetingSessionCoordinator`:

```
              ┌───────────────┐
              │     idle      │
              └───────┬───────┘
                      │ startMeeting()
                      ▼
              ┌───────────────┐
              │   starting    │ (Verifies permissions, initializes audio taps)
              └───────┬───────┘
                      │ audioReady
                      ▼
              ┌───────────────┐
       ┌─────>│   capturing   │ (Audio streaming active)
       │      └───────┬───────┘
       │              │ sttConnected
       │              ▼
       │      ┌───────────────┐
       │      │ transcribing  │ (Live streaming transcripts + user taking notes)
       │      └───────┬───────┘
       │              │ stopMeeting()
       │              ▼
       │      ┌───────────────┐
       │      │   stopping    │ (Halts audio capture, purges temporary buffers)
       │      └───────┬───────┘
       │              │ audioPurged
       │              ▼
       │      ┌───────────────┐
       │      │  processing   │ (Runs AI synthesis, extracts actions & decisions)
       │      └───────┬───────┘
       │              │ aiComplete
       │              ▼
       │      ┌───────────────┐
       │      │   completed   │ (Persisted to SwiftData & indexed for search)
       │      └───────────────┘
       │
       ▼ (On Any Hardware / Network / Auth Fault)
┌───────────────────────────────────────┐
│        failed(MeetingError)           │
│  - permissionDenied                   │
│  - audioDeviceDisconnected            │
│  - transcriptionUnavailable           │
│  - networkDropped (Auto-reconnects)   │
└───────────────────────────────────────┘
```

---

## 6. AI Processing Pipeline & Source-Linking

The post-meeting synthesis pipeline enforces strict grounding to eliminate hallucinations.

```text
[ User Raw Notes ] ───┐
                      │
[ Full Transcript ] ──┼──> [ Prompt Manager ] ──> [ LLM (Claude/GPT-4o) ]
                      │    - Structured Schema
[ Meeting Metadata ] ─┘    - Anti-Hallucination
                                                          │
                                                          ▼
                                                 [ Strict JSON Parser ]
                                                          │
                                            ┌─────────────┴─────────────┐
                                            ▼                           ▼
                                      [ Valid JSON ]             [ Invalid JSON ]
                                            │                           │
                                            ▼                     [ JSON Repair ]
                                  [ Source ID Validator ]               │
                                  - Confirms every action/              ▼
                                    decision references valid     [ Retry LLM ]
                                    segment UUIDs
                                            │
                                            ▼
                                  [ Save Enhanced Note ]
```

### Source-Linking Invariant
Every generated `ActionItem` and `Decision` must include a non-empty `sourceSegmentIDs: [UUID]` array referencing exact transcript segments. If a claim cannot be attributed to a segment, the validation pass flags it or discards the unsupported deduction.

---

## 7. Data Persistence Model (SwiftData)

```text
┌─────────────────┐       1:N       ┌────────────────────────┐
│     Meeting     ├────────────────>│   TranscriptSegment    │
│  - id: UUID     │                 │  - id: UUID            │
│  - title: String│                 │  - speaker: String     │
│  - date: Date   │                 │  - text: String        │
│  - duration: Int│                 │  - start/end: Double   │
└────────┬────────┘                 └────────────────────────┘
         │
         │ 1:N                      ┌────────────────────────┐
         ├─────────────────────────>│       UserNote         │
         │                          │  - id: UUID            │
         │                          │  - text: String        │
         │                          │  - timestamp: Date     │
         │                          └────────────────────────┘
         │
         │ 1:1                      ┌────────────────────────┐
         └─────────────────────────>│     MeetingSummary     │
                                    │  - executiveSummary    │
                                    │  - decisions: [Dec]    │
                                    │  - actions: [Action]   │
                                    │  - quotes: [Quote]     │
                                    └────────────────────────┘
```

---

## 8. Search Engine Architecture
1. **Full-Text Search (FTS5):** Local SQLite FTS virtual table indexing meeting titles, raw notes, transcripts, and enhanced summaries. Provides sub-10ms keyword match with character offset highlighting.
2. **Semantic Search (Phase 2):** Text chunking (500 tokens with 50-token overlap) $\rightarrow$ vector embedding $\rightarrow$ cosine similarity search across historical meetings.
