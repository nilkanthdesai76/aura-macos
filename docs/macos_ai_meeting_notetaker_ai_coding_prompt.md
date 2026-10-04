# Build Prompt — Native macOS AI Meeting Notetaker

## Role

You are a senior macOS software architect and Swift engineer.

Build a **native macOS AI meeting-notetaker application** inspired by the product category represented by Granola, but with completely original branding, UI, code, architecture decisions, prompts, and implementation.

This application is **macOS-only**.

Do not build an iOS, iPadOS, Android, Windows, or web application.

The goal is to create a polished production-quality macOS application that can:

1. Capture microphone audio.
2. Capture system/application meeting audio where macOS permits it.
3. Combine the audio streams.
4. Transcribe the conversation in real time.
5. Let the user write lightweight notes during the meeting.
6. Enhance those notes using AI.
7. Generate summaries, decisions, action items and important points.
8. Store meetings locally.
9. Search previous meetings.
10. Allow the user to ask AI questions about a meeting.
11. Eventually support semantic search across all meetings.
12. Maintain strong privacy and security.
13. Feel like a native Mac application rather than a web wrapper.

---

# 1. PRODUCT CONCEPT

The product is an **AI meeting memory application for macOS**.

The core workflow is:

```text
User starts meeting
        |
        v
Capture microphone + system audio
        |
        v
Real-time transcription
        |
        +----------------------+
        |                      |
        v                      v
   User notes             Transcript
        |                      |
        +----------+-----------+
                   |
                   v
             AI processing
                   |
        +----------+----------+
        |          |          |
        v          v          v
     Summary   Decisions   Actions
        |
        v
     Meeting memory
        |
        +----------+-----------+
        |                      |
        v                      v
      Search                 AI Chat
```

The product should not behave like a visible meeting bot that joins Zoom/Meet/Teams.

The application should run locally on the user's Mac and capture the audio available to the application through supported macOS APIs and permissions.

---

# 2. IMPORTANT IMPLEMENTATION PRINCIPLES

Follow these rules throughout development.

## Native macOS

Use:

- Swift
- SwiftUI
- Swift Concurrency
- AVFoundation
- Core Audio where necessary
- ScreenCaptureKit where appropriate
- SwiftData initially
- Keychain
- URLSession
- WebSocket where required

Do NOT use:

- Electron
- React Native
- Flutter
- Tauri
- a web wrapper

The application should feel native to macOS.

---

# 3. TARGET MACOS

Define a clear minimum macOS version at project creation.

Prefer the newest practical macOS baseline that provides stable access to the required audio and capture APIs.

Before implementing system-audio capture, verify the exact APIs available on the selected minimum macOS version.

Do not assume that an API exists simply because a similar API exists on iOS.

---

# 4. APPLICATION ARCHITECTURE

Use a modular architecture.

Recommended structure:

```text
MeetingAI/
│
├── App/
│   ├── MeetingAIApp.swift
│   ├── AppState.swift
│   ├── AppCoordinator.swift
│   └── DependencyContainer.swift
│
├── Features/
│   ├── Home/
│   ├── UpcomingMeetings/
│   ├── Meetings/
│   ├── LiveMeeting/
│   ├── Transcript/
│   ├── Notes/
│   ├── AIChat/
│   ├── Search/
│   └── Settings/
│
├── Audio/
│   ├── AudioCaptureManager.swift
│   ├── MicrophoneCapture.swift
│   ├── SystemAudioCapture.swift
│   ├── AudioMixer.swift
│   ├── AudioDeviceManager.swift
│   ├── AudioBufferProcessor.swift
│   └── AudioPermissionManager.swift
│
├── Transcription/
│   ├── TranscriptionProvider.swift
│   ├── CloudTranscriptionProvider.swift
│   ├── LocalTranscriptionProvider.swift
│   ├── StreamingTranscriber.swift
│   ├── TranscriptSegment.swift
│   └── SpeakerManager.swift
│
├── AI/
│   ├── AIProvider.swift
│   ├── AIService.swift
│   ├── NoteEnhancer.swift
│   ├── SummaryGenerator.swift
│   ├── ActionItemExtractor.swift
│   ├── DecisionExtractor.swift
│   ├── RecipeEngine.swift
│   ├── RAGService.swift
│   └── PromptManager.swift
│
├── Data/
│   ├── Models/
│   ├── Repositories/
│   ├── Database/
│   └── Persistence/
│
├── Search/
│   ├── FullTextSearch.swift
│   ├── SemanticSearch.swift
│   └── SearchService.swift
│
├── Calendar/
│   ├── CalendarManager.swift
│   └── MeetingEventMapper.swift
│
├── Security/
│   ├── KeychainManager.swift
│   ├── PermissionManager.swift
│   └── PrivacyManager.swift
│
├── Integrations/
│   └── IntegrationManager.swift
│
└── Utilities/
```

Keep features separated from infrastructure.

Do not put audio capture, networking, AI and UI logic inside a single ViewModel.

---

# 5. SWIFT CONCURRENCY

Use modern Swift concurrency.

Prefer:

```swift
actor AudioCaptureManager
actor TranscriptStore
actor MeetingSessionManager
actor AIProcessingManager
```

UI-facing state should be isolated appropriately:

```swift
@MainActor
@Observable
final class MeetingViewModel {
}
```

or use `ObservableObject` where compatibility requires it.

Never block the main thread with:

- audio processing;
- transcription;
- file processing;
- network requests;
- AI requests;
- embeddings;
- search indexing.

---

# 6. CORE MEETING STATE MACHINE

Implement an explicit state machine.

```text
idle
  |
starting
  |
capturing
  |
transcribing
  |
stopping
  |
processing
  |
completed
```

Failure states:

```text
permissionDenied
audioUnavailable
transcriptionDisconnected
networkUnavailable
processingFailed
cancelled
```

Create something like:

```swift
enum MeetingState {
    case idle
    case starting
    case capturing
    case stopping
    case processing
    case completed
    case failed(MeetingError)
}
```

Do not scatter meeting state logic across multiple views.

---

# 7. AUDIO CAPTURE

This is one of the highest-priority engineering problems.

The application needs two logical audio inputs.

## Input 1 — Microphone

Capture:

- MacBook microphone;
- external microphone;
- USB microphone;
- supported Bluetooth microphone/headset.

## Input 2 — System/Application Audio

Capture meeting participant audio or supported system/application audio through the appropriate modern macOS capture API.

Investigate and use:

- ScreenCaptureKit;
- Core Audio;
- AVFoundation;
- Audio Units where required.

Do not immediately implement a virtual audio driver unless native macOS capture cannot satisfy the required use case.

A virtual driver adds installation, permissions, signing, compatibility and support complexity.

---

# 8. AUDIO PIPELINE

Implement:

```text
Microphone
    |
    v
Microphone Capture
    |
    +------------------+
                       |
                       v
                  Audio Mixer
                       ^
                       |
    +------------------+
    |
System/Application Audio
    |
    v
System Audio Capture
```

Then:

```text
Audio Mixer
    |
    v
Format Normalizer
    |
    v
PCM Audio Frames
    |
    v
Voice Activity Detection
    |
    v
Streaming Transcription
```

The mixer must handle:

- different sample rates;
- channel counts;
- audio formats;
- volume normalization;
- device changes;
- temporary unavailable devices.

Do not write audio processing on the main thread.

---

# 9. AUDIO DEVICE MANAGEMENT

Support:

- default microphone;
- selected microphone;
- default output device;
- device switching;
- Bluetooth connection/disconnection;
- headset connection/disconnection;
- device unavailable;
- sleep/wake.

Expose a simple Settings UI:

```text
Microphone
[ MacBook Microphone ▼ ]

System Audio
[ Default Output ▼ ]

Test Audio
[ Test ]
```

If a device disappears, recover gracefully.

Do not crash.

---

# 10. AUDIO VISUALIZATION

During a meeting show a lightweight audio indicator.

Example:

```text
● Transcribing

Microphone ███████░░
System     █████░░░░
```

Do not make this CPU-heavy.

Use a lightweight amplitude/level meter rather than rendering every raw audio frame.

---

# 11. PERMISSIONS

Create a central PermissionManager.

Handle:

- microphone permission;
- system/display/audio capture permission as required by the chosen architecture;
- calendar permission if calendar integration is implemented.

Never show a vague permission error.

Example:

```text
System Audio Access Required

Meeting audio cannot be captured yet.

Open System Settings
→ Privacy & Security
→ Screen & System Audio Recording

[ Open System Settings ]
[ Try Again ]
```

Deep-link to the appropriate System Settings page where supported.

---

# 12. PRIVACY-FIRST AUDIO HANDLING

Treat raw meeting audio as highly sensitive.

Recommended architecture:

```text
Audio
 |
Temporary processing buffer
 |
Transcription
 |
Transcript saved
 |
Audio discarded
```

Do not permanently store meeting audio by default.

If a future feature supports recording, it must be explicit and separately controlled.

Create:

```swift
protocol AudioRetentionPolicy {
    var shouldPersistAudio: Bool { get }
}
```

Default:

```swift
shouldPersistAudio = false
```

---

# 13. TRANSCRIPTION ARCHITECTURE

Do not hard-code the application to one transcription provider.

Create:

```swift
protocol TranscriptionProvider {
    func start() async throws
    func send(audio: AVAudioPCMBuffer) async throws
    func stop() async throws
}
```

Implement:

```text
CloudTranscriptionProvider
LocalTranscriptionProvider
```

The first production version may use cloud transcription.

Keep local transcription as a pluggable future implementation.

---

# 14. STREAMING TRANSCRIPTION

The user should see transcription while the meeting is happening.

Example:

```text
10:04:12

John:
We need to finalize the pricing model...

10:04:18

Sarah:
I think the current plan is too expensive...
```

Support:

- partial transcription;
- final transcription;
- timestamps;
- confidence if available;
- speaker ID if available.

Do not append duplicate partial results.

Use stable segment IDs.

---

# 15. TRANSCRIPT DATA MODEL

Create:

```swift
struct TranscriptSegment: Identifiable, Codable {
    let id: UUID
    let meetingID: UUID

    var startTime: TimeInterval
    var endTime: TimeInterval

    var speakerID: UUID?
    var text: String

    var confidence: Float?
    var isFinal: Bool
}
```

Partial segments can be updated.

Final segments should become stable records.

---

# 16. SPEAKER DIARIZATION

Initially support:

```text
Speaker 1
Speaker 2
Speaker 3
```

Then allow mapping:

```text
Speaker 1 → John
Speaker 2 → Sarah
Speaker 3 → Mike
```

Calendar attendees can provide candidate identities.

Never confidently assign identities without sufficient evidence.

Allow manual correction.

Design the model so speaker attribution can be upgraded later.

---

# 17. LIVE MEETING UI

Create a polished native macOS meeting interface.

Recommended layout:

```text
┌────────────────────────────────────────────────────┐
│ Product Planning                     10:32 AM       │
│ ● Transcribing                                     │
├──────────────────────┬─────────────────────────────┤
│                      │                             │
│ My Notes             │ Transcript                 │
│                      │                             │
│ Pricing concern      │ John:                      │
│                      │ We need to discuss...      │
│ Launch decision      │                             │
│                      │ Sarah:                     │
│ API reliability      │ The main issue is...       │
│                      │                             │
│                      │                             │
├──────────────────────┴─────────────────────────────┤
│                    [ Stop Meeting ]                │
└────────────────────────────────────────────────────┘
```

The notes editor should be fast.

Do not force users to interact with complex AI UI during the meeting.

---

# 18. USER NOTES

User notes are first-class data.

Model:

```swift
struct UserNote: Identifiable, Codable {
    let id: UUID
    let meetingID: UUID

    var text: String
    var createdAt: Date
    var updatedAt: Date
    var position: Int
}
```

Support:

- typing;
- editing;
- deleting;
- reordering if practical.

The user should be able to write:

```text
Pricing concern
```

rather than a full sentence.

---

# 19. HUMAN + AI NOTE SYSTEM

After the meeting, combine:

```text
User Notes
+
Transcript
+
Meeting Metadata
```

Then generate:

```text
Summary
Key Discussion Points
Decisions
Action Items
Open Questions
Important Quotes
```

The user's notes should act as attention/context signals.

For example:

User note:

```text
Pricing concern
```

The AI should locate relevant transcript discussion and expand it.

---

# 20. AI PROVIDER ABSTRACTION

Create:

```swift
protocol AIProvider {
    func generate(
        prompt: String,
        context: AIContext
    ) async throws -> AIResponse
}
```

Potential implementations:

```text
OpenAI
Anthropic
Gemini
LocalModel
```

The rest of the application should not know which provider is being used.

---

# 21. AI OUTPUT MUST BE STRUCTURED

Do not depend on free-form Markdown.

Use structured JSON.

Example:

```json
{
  "summary": "...",
  "discussionPoints": [],
  "decisions": [],
  "actionItems": [],
  "openQuestions": [],
  "importantQuotes": []
}
```

Parse and validate the JSON before rendering.

If parsing fails:

1. retry using a repair strategy;
2. log a non-sensitive diagnostic;
3. show a graceful UI state.

Never crash because an LLM returned invalid JSON.

---

# 22. AI DATA MODELS

Example:

```swift
struct MeetingSummary: Codable {
    var summary: String
    var discussionPoints: [DiscussionPoint]
    var decisions: [Decision]
    var actionItems: [ActionItem]
    var openQuestions: [OpenQuestion]
    var quotes: [ImportantQuote]
}
```

Action item:

```swift
struct ActionItem: Identifiable, Codable {
    let id: UUID
    var title: String
    var owner: String?
    var deadline: Date?
    var sourceSegmentIDs: [UUID]
}
```

Decision:

```swift
struct Decision: Identifiable, Codable {
    let id: UUID
    var content: String
    var sourceSegmentIDs: [UUID]
}
```

---

# 23. SOURCE-LINKED AI

This is mandatory for trustworthy AI.

Every AI-generated:

- decision;
- action item;
- important quote;
- significant claim

should store:

```text
sourceSegmentIDs
```

Example:

```text
Decision

Launch beta in October.

[ View Source ]
```

Clicking:

```text
View Source
```

jumps to the exact transcript segment.

This is essential for reducing hallucination concerns.

---

# 24. AI PROMPT RULES

Use a strict system prompt.

Conceptually:

```text
You are a meeting intelligence assistant.

Transform the supplied transcript and user notes into
accurate structured meeting documentation.

Rules:

1. Never invent facts.
2. Never invent decisions.
3. Never invent commitments.
4. Never invent quotes.
5. Never invent dates.
6. Preserve uncertainty.
7. Prefer evidence from the transcript.
8. Treat user notes as priority/context signals.
9. Attribute statements to speakers when possible.
10. Every extracted action or decision must reference source transcript segments.
11. If information is unavailable, explicitly say so.
12. Return valid structured JSON only.
```

Keep prompts versioned.

Do not scatter prompt strings throughout the codebase.

---

# 25. MEETING RECIPES / TEMPLATES

Implement an extensible recipe system.

Examples:

## General Meeting

```text
Summary
Discussion
Decisions
Action Items
Open Questions
```

## Sales Call

```text
Customer Needs
Pain Points
Objections
Budget
Timeline
Competitors
Next Steps
```

## Product Meeting

```text
Problem
Proposed Solution
Decisions
Trade-offs
Technical Risks
Open Questions
Owners
```

## 1:1

```text
Topics
Feedback
Goals
Blockers
Follow-ups
```

## Engineering Meeting

```text
Architecture Decisions
Technical Issues
Risks
Dependencies
API Changes
Action Items
```

Create:

```swift
struct AIRecipe: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let systemPrompt: String
}
```

---

# 26. MEETING PROCESSING PIPELINE

After Stop:

```text
Stop Meeting
     |
Finalize Transcript
     |
Persist Transcript
     |
Delete Temporary Audio
     |
Build AI Context
     |
Run Enhancement
     |
Validate Structured Output
     |
Persist Summary
     |
Index Meeting
     |
Mark Completed
```

Do not block the UI.

Show:

```text
Processing meeting...

✓ Transcript
✓ Notes
✓ Summary
✓ Action items
✓ Search index
```

---

# 27. LOCAL DATABASE

Start with SwiftData for the native prototype.

Entities:

```text
Meeting
Participant
TranscriptSegment
UserNote
MeetingSummary
DiscussionPoint
Decision
ActionItem
OpenQuestion
ImportantQuote
```

Design repositories:

```swift
protocol MeetingRepository {
    func save(_ meeting: Meeting) async throws
    func fetch(id: UUID) async throws -> Meeting?
    func fetchAll() async throws -> [Meeting]
    func delete(id: UUID) async throws
}
```

Do not make SwiftData APIs directly responsible for every feature.

This allows a future migration to PostgreSQL/cloud sync.

---

# 28. MEETING MODEL

Example:

```swift
struct Meeting {
    let id: UUID

    var title: String
    var startDate: Date
    var endDate: Date?

    var meetingURL: URL?
    var calendarEventID: String?

    var participants: [Participant]

    var state: MeetingState

    var transcriptStatus: TranscriptStatus
    var aiProcessingStatus: AIProcessingStatus
}
```

---

# 29. MEETING HISTORY

Create:

```text
Meetings

Today
 ├── Product Planning
 └── Acme Review

Yesterday
 ├── Engineering Sync
 └── 1:1 with Sarah

Older
 ├── Customer Research
 └── Architecture Review
```

Each meeting should show:

- title;
- date/time;
- participants;
- short summary;
- action item count;
- duration;
- processing state.

---

# 30. SEARCH

Implement phase 1 using local full-text search.

Search:

```text
pricing
API
Sarah
October launch
Acme
```

Results should identify:

```text
Meeting
Transcript match
Note match
Decision match
Action item match
```

Clicking a result should open the relevant meeting and highlight the match.

---

# 31. SEMANTIC SEARCH

Architecture:

```text
Transcript
   |
Chunking
   |
Embedding
   |
Vector Index
```

Search:

```text
"What did customers dislike about pricing?"
```

should find discussions even if the exact word "dislike" was never spoken.

Use a vector-capable database when cloud search is introduced.

For an initial native-only prototype, keep the semantic search abstraction separate from the local database.

---

# 32. AI CHAT FOR ONE MEETING

Add:

```text
Ask about this meeting...
```

Examples:

```text
What were the main concerns?

What did Sarah agree to?

What decisions did we make?

What should I follow up on?

Why did we delay the launch?
```

Architecture:

```text
Question
   |
Meeting transcript + notes
   |
Relevant context selection
   |
LLM
   |
Answer
   |
Source links
```

Never send unrelated meetings into the context for a single-meeting question.

---

# 33. CROSS-MEETING AI CHAT

Later implement:

```text
Ask your meetings...
```

Examples:

```text
What commitments did I make this week?

What has Acme said about pricing?

How has the project direction changed?

What decisions were made about authentication?
```

Architecture:

```text
Question
   |
Query analysis
   |
Metadata filters
   |
Full-text + semantic search
   |
Relevant transcript chunks
   |
LLM
   |
Answer + Sources
```

---

# 34. CALENDAR INTEGRATION

Make calendar integration modular.

Initially support:

- EventKit where appropriate;
- Google Calendar through OAuth/API if cloud integration is later required.

Calendar metadata:

```text
Meeting title
Start time
End time
Attendees
Meeting URL
Organizer
Calendar
```

Do not automatically start recording just because a meeting exists.

The user should explicitly start capture.

---

# 35. UPCOMING MEETINGS

Home screen:

```text
Upcoming

10:00
Acme Product Review
John · Sarah · Mike

11:30
Engineering Sync
Team

2:00
1:1
Sarah

[ Start Notes ]
```

Starting notes should create a meeting workspace.

---

# 36. MENU BAR SUPPORT

Add a native macOS menu-bar item.

Example:

```text
MeetingAI

● Ready

Upcoming:
10:00 Acme Product Review

[ Start Meeting ]
[ Open App ]
[ Settings ]
[ Quit ]
```

When recording:

```text
● Transcribing
```

This makes the application convenient during meetings.

---

# 37. GLOBAL HOTKEY

Implement as a future feature.

Example:

```text
⌥⌘M
```

Behavior:

```text
Start Meeting
```

or:

```text
Stop Meeting
```

Do not make the hotkey conflict with common macOS shortcuts.

Make it configurable.

---

# 38. NATIVE MACOS UX

Use:

- NavigationSplitView;
- Toolbar;
- Sidebar;
- searchable;
- sheets;
- popovers;
- keyboard shortcuts;
- context menus;
- native window management;
- menu bar;
- system appearance;
- accessibility.

Support:

```text
Light Mode
Dark Mode
System Appearance
```

Do not build a web-style UI.

---

# 39. KEYBOARD SHORTCUTS

Recommended:

```text
⌘K       Search
⌘Enter   Start/Stop meeting
⌘F       Search transcript
⌘1       Home
⌘2       Meetings
⌘3       Search
Esc      Close overlay
```

Make shortcuts discoverable through menus.

---

# 40. SETTINGS

Sections:

```text
General
Audio
Transcription
AI
Calendar
Integrations
Privacy
Shortcuts
About
```

Audio:

```text
Microphone
System Audio
Input Device
Test
```

AI:

```text
Provider
Model
API configuration
Default recipe
```

Privacy:

```text
Keep audio recordings
[ Off ]

Delete temporary audio automatically
[ On ]

Analytics
[ Optional ]
```

---

# 41. SECURITY

Never embed secrets directly in the application.

Use:

```text
Keychain
```

for:

- API tokens;
- OAuth refresh tokens;
- encryption keys where applicable.

Do not store API keys in:

```text
UserDefaults
Swift source code
Info.plist
Git repository
```

---

# 42. NETWORKING

Use `URLSession`.

For real-time transcription use:

```text
WebSocket
```

or the provider's supported streaming mechanism.

Create:

```swift
protocol NetworkClient {
    func request<T: Decodable>(...) async throws -> T
}
```

Keep networking separate from features.

---

# 43. ERROR HANDLING

Every subsystem must expose meaningful errors.

Examples:

```swift
enum AudioError: Error {
    case permissionDenied
    case deviceUnavailable
    case initializationFailed
    case formatUnsupported
}
```

```swift
enum TranscriptionError: Error {
    case connectionFailed
    case authenticationFailed
    case providerUnavailable
    case invalidResponse
}
```

The UI must translate these into useful user-facing messages.

---

# 44. OFFLINE BEHAVIOR

At minimum:

- previously saved meetings must remain accessible;
- user notes should work offline;
- local search should work offline;
- the app should not crash when transcription network access disappears.

If cloud transcription disconnects:

```text
Transcription connection lost.

Reconnecting...
```

Retry with exponential backoff.

Do not create duplicate transcript segments during reconnection.

---

# 45. AI RETRIES

For AI processing:

```text
Attempt 1
   |
failure
   |
Attempt 2
   |
failure
   |
Attempt 3
```

Use bounded retries.

Do not endlessly retry expensive LLM calls.

---

# 46. LOGGING

Create structured logging using Apple's logging system.

Use:

```swift
import OSLog
```

Categories:

```text
audio
transcription
ai
database
search
calendar
security
ui
```

Never log:

- raw meeting audio;
- complete transcripts;
- API keys;
- OAuth tokens;
- private user content.

---

# 47. PERFORMANCE

Target:

- smooth 60 FPS UI;
- minimal CPU usage while idle;
- no blocking audio processing;
- bounded memory;
- efficient transcript rendering;
- lazy loading for long transcripts.

For very long meetings, do not render thousands of transcript rows at once.

Use lazy containers and pagination/virtualization.

---

# 48. LONG MEETING SUPPORT

Test:

```text
30 minutes
1 hour
2 hours
4 hours
```

Transcript storage should remain efficient.

Avoid one massive JSON document containing the entire transcript.

Store segments individually.

---

# 49. AUDIO RELIABILITY TEST MATRIX

Test:

```text
MacBook microphone
USB microphone
AirPods
Bluetooth headset
Wired headset
External display
HDMI audio
External speakers
```

Also test:

```text
Change output device during meeting
Disconnect microphone
Reconnect microphone
Sleep Mac
Wake Mac
Lock screen
Unlock
Network disconnect
Network reconnect
```

---

# 50. MEETING APP TEST MATRIX

Test with applications/browser meetings such as:

```text
Google Meet
Zoom
Microsoft Teams
Slack Huddles
Browser audio
Other system audio
```

The product should not depend on one meeting provider.

---

# 51. PRIVACY REQUIREMENTS

The application deals with potentially confidential meetings.

Implement:

```text
Data minimization
Encryption in transit
Secure local storage
Keychain
Explicit permissions
Audio deletion
Account/data deletion
Privacy settings
```

Provide a clear privacy screen explaining:

```text
What is captured?
What is stored?
Where is transcription performed?
Is audio retained?
Is AI processing cloud-based?
Is data used to train models?
```

Do not make claims that cannot be technically guaranteed.

---

# 52. PARTICIPANT TRANSPARENCY

The application should not be designed for covert recording.

Make the transcription state visible:

```text
● Transcribing
```

Provide clear user-facing information about capture and applicable consent/disclosure requirements.

Do not implement stealth recording features.

---

# 53. AI HALLUCINATION CONTROL

This is mandatory.

For factual answers:

```text
Answer only from retrieved meeting evidence.

If the information is not present:
say that it was not found.

Never fabricate:
- names
- dates
- decisions
- action items
- quotes
- commitments
```

Always expose sources for AI-generated meeting facts when possible.

---

# 54. ACTION ITEM EXTRACTION

Extract only explicit or strongly supported commitments.

Bad:

```text
John discussed the API.
```

Do not turn this into:

```text
John must fix the API.
```

Good:

```text
John: "I'll investigate the API latency tomorrow."
```

becomes:

```text
John
Investigate API latency
Due: Tomorrow
```

with source transcript IDs.

---

# 55. DECISION EXTRACTION

Only create a decision if the conversation supports it.

Example:

```text
Sarah:
Let's launch the beta in October.

John:
Agreed.

Mike:
Yes.
```

Output:

```text
Decision:
Beta launch targeted for October.
```

Source:

```text
segments 102, 103, 104
```

---

# 56. QUOTE EXTRACTION

Quotes must come from actual transcript text.

Do not let the model invent quotations.

Store:

```swift
struct ImportantQuote {
    var text: String
    var speakerID: UUID?
    var sourceSegmentID: UUID
    var timestamp: TimeInterval
}
```

---

# 57. LOCAL AI OPTION

Architect for future local AI.

Possible architecture:

```text
AIProvider
  |
  +-- CloudAIProvider
  |
  +-- LocalAIProvider
```

Similarly:

```text
TranscriptionProvider
  |
  +-- Cloud
  |
  +-- Local
```

This enables a future:

```text
Private Mode

Audio: local
Transcription: local
Embeddings: local
AI: local
Storage: local
```

Do not implement local models first unless required for the MVP.

---

# 58. RECOMMENDED MVP

Build only:

```text
1. Native SwiftUI macOS app
2. Permission flow
3. Microphone capture
4. System/application audio capture
5. Audio mixing
6. Streaming transcription
7. Live transcript
8. User notes
9. Stop meeting
10. AI summary
11. Decisions
12. Action items
13. Local meeting history
14. Meeting detail page
15. Basic search
16. Privacy controls
```

Do NOT build initially:

```text
CRM
Slack integration
Jira integration
MCP
Team workspaces
Complex billing
Advanced RAG
Complex calendar automation
```

---

# 59. PHASE 2

After MVP is stable:

```text
1. Calendar integration
2. Speaker diarization
3. Meeting recipes
4. Transcript search
5. AI chat for one meeting
6. Semantic search
7. Cross-meeting AI
8. Notion export
9. Slack integration
10. Better onboarding
```

---

# 60. PHASE 3

Then:

```text
1. MCP
2. Jira
3. Linear
4. CRM integrations
5. Meeting preparation
6. Daily briefing
7. Personal AI memory
8. Local transcription
9. Local AI
10. Cloud sync
11. Team workspaces
```

---

# 61. PRODUCT DIFFERENTIATION

Do not create an exact visual clone of an existing product.

Potential differentiation:

## Engineering Meeting Mode

Automatically extract:

```text
Architecture Decisions
Technical Risks
API Changes
Dependencies
Jira References
Action Items
```

## Developer Memory

User can ask:

```text
Why did we choose PostgreSQL?
```

The system searches previous engineering meetings.

## Multilingual Meetings

Design transcription/AI architecture so future support can include:

```text
English
Hindi
Gujarati
English + Hindi
English + Gujarati
```

Do not hard-code the UI around English-only content.

---

# 62. DATA FLOW

Implement this conceptual flow:

```text
                   ┌──────────────┐
                   │   Calendar   │
                   └──────┬───────┘
                          │
                          v
                   Meeting Context
                          │
                          v
┌──────────┐      ┌───────────────┐      ┌──────────────┐
│Mic Input │─────>│               │      │              │
└──────────┘      │ Audio Mixer   │─────>│ Transcriber  │
                  │               │      │              │
┌──────────┐      └───────────────┘      └──────┬───────┘
│System   │───────────────^                     │
│Audio    │                                     v
└──────────┘                              Transcript
                                             │
                         ┌───────────────────┤
                         │                   │
                         v                   v
                    User Notes           AI Engine
                         │                   │
                         └────────┬──────────┘
                                  v
                         Meeting Intelligence
                                  |
                ┌─────────────────┼────────────────┐
                v                 v                v
             Summary          Decisions       Action Items
                |                 |                |
                └─────────────────┼────────────────┘
                                  v
                           Search / Memory
                                  |
                                  v
                               AI Chat
```

---

# 63. IMPLEMENTATION RULES FOR THE CODING AI

When implementing this project:

## Rule 1

Do not generate the entire application in one giant code dump.

Work in phases.

## Rule 2

Before changing architecture, inspect the current code.

## Rule 3

Never overwrite working code unnecessarily.

## Rule 4

Keep the application compiling after each logical milestone.

## Rule 5

Use small commits/checkpoints.

## Rule 6

Do not introduce dependencies without explaining why they are needed.

## Rule 7

Prefer Apple frameworks when they solve the problem well.

## Rule 8

Do not use deprecated APIs when a modern supported API exists.

## Rule 9

Do not invent macOS APIs.

Verify API availability and signatures against the installed SDK/documentation.

## Rule 10

Handle permissions and failure states before polishing the happy path.

---

# 64. DEVELOPMENT WORKFLOW

Use this sequence.

## Step 1 — Repository inspection

Analyze:

```text
Xcode project
Swift version
macOS deployment target
existing dependencies
architecture
build configuration
entitlements
signing
```

If this is a new project, create the architecture from scratch.

## Step 2 — Technical spike

Before building UI, prove:

```text
Microphone capture
+
System audio capture
+
Audio mixing
+
Transcription
```

This is the highest-risk component.

## Step 3 — Build meeting session

Create:

```text
Start
Capture
Transcribe
Stop
Save
```

## Step 4 — Build notes UI

Add:

```text
User notes
Transcript
Meeting detail
```

## Step 5 — Add AI

Implement:

```text
Summary
Decisions
Actions
```

## Step 6 — Search

Implement local full-text search.

## Step 7 — Improve UX

Add:

```text
Menu bar
Shortcuts
Onboarding
Settings
Error states
```

## Step 8 — Add advanced intelligence

Implement:

```text
Recipes
RAG
AI chat
Semantic search
```

---

# 65. REQUIRED DOCUMENTATION

Maintain:

```text
README.md
ARCHITECTURE.md
AUDIO_ARCHITECTURE.md
TRANSCRIPTION.md
AI_ARCHITECTURE.md
PRIVACY.md
TESTING.md
ROADMAP.md
```

Document important architectural decisions.

---

# 66. REQUIRED TESTS

Write unit tests for:

```text
Meeting state machine
Transcript merging
Partial transcript handling
Action item parsing
Decision parsing
Search
AI JSON parsing
Repository operations
```

Integration tests for:

```text
Audio capture
Transcription provider
AI provider
Database
```

UI tests for:

```text
Start meeting
Stop meeting
Permission denied
Meeting processing
Meeting detail
Search
AI chat
```

---

# 67. DEFINITION OF DONE FOR MVP

The MVP is complete only when:

```text
[ ] App launches reliably
[ ] Permissions work
[ ] Microphone capture works
[ ] System audio capture works on supported configurations
[ ] Both streams can be processed
[ ] Transcription is real-time
[ ] Transcript is stable
[ ] User can write notes
[ ] User can stop meeting
[ ] Transcript is persisted
[ ] Audio is not retained by default
[ ] AI summary works
[ ] Decisions work
[ ] Action items work
[ ] Sources are linked to transcript
[ ] Meeting history works
[ ] Search works
[ ] Error states are handled
[ ] App works in dark/light mode
[ ] No main-thread blocking
[ ] No secrets are embedded
[ ] Logging does not expose meeting content
[ ] Tests pass
```

---

# 68. CRITICAL TECHNICAL PRIORITIES

Prioritize these in this order:

### P0

Reliable audio capture.

### P0

Reliable streaming transcription.

### P0

Meeting session state management.

### P1

User notes and transcript UI.

### P1

AI enhancement.

### P1

Local persistence.

### P2

Search.

### P2

Calendar.

### P2

Speaker diarization.

### P3

RAG.

### P3

AI chat.

### P3

Integrations.

### P4

MCP and advanced automation.

---

# 69. FIRST IMPLEMENTATION TASK

Start by creating a technical spike rather than implementing the entire application.

Build a minimal macOS SwiftUI application with:

```text
Window
   |
Start Capture
   |
Microphone
   +
System/Application Audio
   |
Audio Mixer
   |
Audio Level Meter
   |
Stop
```

Then prove that the resulting PCM stream can be sent to a streaming transcription provider.

The spike should output:

```text
Audio capture: PASS
Microphone: PASS
System audio: PASS
Mixer: PASS
Transcription connection: PASS
Live transcript: PASS
```

Only after this works should the rest of the application be built.

---

# 70. EXPECTED CODING-AGENT BEHAVIOR

Before writing code:

1. Inspect the repository.
2. Identify the existing architecture.
3. Check the macOS SDK/API availability.
4. Identify required entitlements.
5. Identify required permissions.
6. Identify dependencies.
7. Produce a short implementation plan.
8. Implement one milestone.
9. Build the project.
10. Run tests.
11. Fix compiler warnings/errors.
12. Summarize changes.
13. Move to the next milestone.

Do not pretend that a feature works if it has not been tested.

---

# 71. FINAL PRODUCT TARGET

The finished application should feel like:

> A native Mac application that quietly sits alongside meetings, captures supported meeting audio, creates a live transcript, lets the user jot down lightweight notes, and transforms the conversation into trustworthy structured knowledge that can be searched and queried later.

The long-term architecture should evolve from:

```text
Meeting Notetaker
```

into:

```text
Personal Meeting Memory
```

where the user can ask:

```text
What did we discuss?

What did we decide?

What did I promise?

What is still unresolved?

What did this customer say last month?

Why did we make this decision?

What should I prepare before today's meeting?
```

The application should answer those questions using **retrieved meeting evidence**, not invented information.

---

# 72. START NOW

Begin with the technical spike.

Do not implement the full product immediately.

First:

```text
1. Create/inspect the native macOS project.
2. Configure entitlements.
3. Implement microphone permission.
4. Implement system/application audio capture using the most appropriate supported Apple API.
5. Build an audio mixer.
6. Display audio levels.
7. Stream audio to a transcription provider through an abstraction.
8. Display the live transcript.
9. Add robust error handling.
10. Test on a real Mac.
```

After this milestone succeeds, report:

```text
Architecture
Files created
APIs used
Entitlements required
Permissions required
Audio capture limitations discovered
Transcription latency
Known issues
Next milestone
```

Then continue incrementally toward the full meeting-intelligence application.

---

# IMPORTANT

This is an original implementation.

Use Granola only as inspiration for the general product category and publicly observable workflow.

Do not copy:

- Granola source code
- Granola branding
- Granola logo
- Granola UI pixel-for-pixel
- proprietary prompts
- proprietary assets
- private implementation details

Build an independent native macOS product with its own:

- name
- design system
- architecture
- prompts
- data models
- code
- user experience
