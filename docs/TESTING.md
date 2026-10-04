# Quality Assurance & Testing Strategy (TESTING.md)

## Quality Target: 90%+ Core Logic Coverage & Zero-Crash Audio Resiliency

Meeting audio and live transcription are real-time, mission-critical systems. This document outlines the test architecture, automated test suites, hardware test matrix, and AI evaluation frameworks.

---

## 1. Test Pyramid & Coverage Matrix

```
             ┌──────────────────────┐
             │       UI Tests       │  (10%) -> Start/Stop Session, Permission Alerts
             ├──────────────────────┤
             │  Integration Tests   │  (30%) -> Audio Pipeline, WebSocket STT, LLM Orchestration
             ├──────────────────────┤
             │      Unit Tests      │  (60%) -> State Machine, JSON Parsers, FTS Search, Segment Merging
             └──────────────────────┘
```

---

## 2. Unit Testing Suite

### 2.1 Meeting State Machine Tests (`MeetingStateMachineTests.swift`)
* Validate strict valid state transitions: `idle -> starting -> capturing -> transcribing -> stopping -> processing -> completed`.
* Verify error transitions when permissions are denied or audio routes disappear.
* Verify rejection of illegal transitions (e.g. `completed -> transcribing`).

### 2.2 Streaming Transcript & Segment Stability Tests (`StreamingTranscriberTests.swift`)
* **Interim Segment Updates:** Verify that interim transcript updates with the same `segmentID` overwrite text without appending duplicate entries.
* **Final Segment Stability:** Verify that when `isFinal: true` is received, the segment is locked and immutable.
* **Out-of-Order Packets:** Test sequence number reordering when WebSocket packets arrive out of chronological order.

### 2.3 AI JSON Parsing & Repair Tests (`AIParserTests.swift`)
* Verify parsing of valid structured JSON matching schema.
* **Malformed JSON Repair:** Test regex/fixup parser on common LLM formatting flaws (trailing commas, missing closing brackets, Markdown code fences ```json ... ```).
* **Source-Linking Integrity:** Confirm parser rejects or flags action items that do not contain valid `sourceSegmentIDs`.

### 2.4 Local Search & Indexing Tests (`SearchServiceTests.swift`)
* Insert 100 test meetings into SQLite FTS5 index.
* Verify sub-5ms exact and prefix matching for terms like `"PostgreSQL"`, `"timeline"`, `"budget"`.
* Verify highlight offset calculations.

---

## 3. Integration Testing & Mock Providers

### 3.1 Mock Transcription Provider (`MockTranscriptionProvider.swift`)
* Simulates streaming audio over WebSocket without making external network calls.
* Injects delayed synthetic transcript segments to test UI responsiveness and scrolling.

### 3.2 Mock AI Provider (`MockAIProvider.swift`)
* Returns deterministic JSON fixtures for different meeting recipes (Engineering, Sales, 1:1) to test UI rendering in milliseconds.

---

## 4. Hardware & Audio Reliability Test Matrix

Run manual verification on physical Mac hardware across the following audio environments:

| Test Case | Scenario | Expected Behavior |
| :--- | :--- | :--- |
| **TC-AUD-01** | Internal MacBook Mic + Speakers | Clean capture, audio levels active on both channels. |
| **TC-AUD-02** | AirPods / Bluetooth Headset connected | Audio captures both user mic and incoming Bluetooth stream without latency drift. |
| **TC-AUD-03** | Device Disconnection mid-meeting | Disconnecting USB mic or AirPods switches gracefully to built-in mic without crashing. |
| **TC-AUD-04** | macOS Sleep / Wake Cycle | Closing laptop lid pauses stream; waking re-establishes capture and notifies user. |
| **TC-AUD-05** | ScreenCaptureKit Permission Denied | App displays dedicated settings guidance sheet with 1-click button to macOS System Settings. |

---

## 5. Meeting App Compatibility Matrix

Verify audio capture fidelity across all major macOS communication apps:

* [x] **Google Meet** (Google Chrome & Safari)
* [x] **Zoom Desktop Client**
* [x] **Microsoft Teams Client & Web**
* [x] **Slack Huddles**
* [x] **Loom Screen & Voice Recording**

---

## 6. AI Hallucination & Groundedness Evaluation

We execute automated evaluation tests against synthetic meeting transcripts to verify AI fidelity:

1. **Unanswered Topic Test:** Inject query about a topic never spoken in the transcript. Verify AI response explicitly states: *"This was not discussed during the meeting."* (0% hallucination tolerance).
2. **Quote Exactness Test:** Compare extracted `ImportantQuote` fields against the raw transcript. Assert Levenshtein distance equals 0 (exact character match).
3. **Action Item Grounding Test:** Verify every extracted action item references a segment where the assigned owner actually spoke or was directly assigned the task.
