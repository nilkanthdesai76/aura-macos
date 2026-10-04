# Swift Code Style & Engineering Standards (CODE_STYLE.md)

## Standard: Swift 5.9+ / Swift 6 Ready
**Platform:** macOS 14.0+  
**Style Guide:** Apple Swift API Design Guidelines + Strict Concurrency Standards

---

## 1. Swift Concurrency & Thread Safety Rules

### 1.1 Actor Isolation
* Use `actor` for any class that holds mutable state accessed across asynchronous boundaries (e.g., `AudioCaptureManager`, `StreamingTranscriber`, `TranscriptStore`).
* Use `@MainActor` on all ViewModels, UI state managers, and SwiftUI views.

```swift
// GOOD: Actor isolation for audio processing
public actor AudioCaptureManager {
    private var isRecording: Bool = false
    
    public func startCapture() async throws { ... }
}

// GOOD: MainActor isolation for presentation state
@MainActor
@Observable
public final class LiveMeetingViewModel {
    public var liveTranscript: [TranscriptSegment] = []
    public var userNotes: String = ""
}
```

### 1.2 No Thread Blocking
* **Never** call synchronous blocking operations (`Thread.sleep`, heavy file I/O, synchronous locks, synchronous network calls) inside `@MainActor` or audio callback threads.
* Audio render taps must remain lightweight ($< 5\text{ms}$) to prevent CoreAudio buffer overruns / audio glitches.

### 1.3 `Sendable` Concurrency Checking
* Ensure all data models transferred between actors conform to `Sendable` (e.g., immutable `struct` types or `@unchecked Sendable` where thread safety is mathematically proven).

---

## 2. SwiftUI Component Patterns

### 2.1 View Decomposition
* Views must not exceed **150 lines of code**. Large views must be broken into smaller, reusable subviews (`TranscriptSegmentRow`, `AudioLevelMeterBar`, `DecisionCardView`).
* Extract view logic into computed properties or dedicated ViewModels.

```swift
// GOOD: Clean component extraction
struct LiveMeetingView: View {
    @State private var viewModel: LiveMeetingViewModel
    
    var body: some View {
        HSplitView {
            NotesEditorView(text: $viewModel.userNotes)
                .frame(minWidth: 300)
            TranscriptStreamView(segments: viewModel.liveTranscript)
                .frame(minWidth: 350)
        }
        .toolbar {
            MeetingToolbarControls(state: viewModel.state, onStop: viewModel.stopMeeting)
        }
    }
}
```

### 2.2 Navigation & macOS System Patterns
* Use `NavigationSplitView` for multi-column macOS navigation.
* Use native macOS modifiers: `.keyboardShortcut()`, `.help()`, `.searchable()`, `.inspector()`.

---

## 3. Strongly-Typed Error Handling

Avoid generic `Error` or `NSError`. Every module must define explicit, domain-specific typed error enums conforming to `LocalizedError`.

```swift
public enum AudioCaptureError: LocalizedError {
    case microphonePermissionDenied
    case systemAudioUnavailable
    case deviceDisconnected(String)
    case unsupportedAudioFormat(String)
    
    public var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            return "Microphone access was denied. Please grant permission in System Settings."
        case .systemAudioUnavailable:
            return "System audio capture is not available on this macOS version."
        case .deviceDisconnected(let name):
            return "Audio device '\(name)' was disconnected."
        case .unsupportedAudioFormat(let format):
            return "Unsupported audio format: \(format)."
        }
    }
}
```

---

## 4. Naming Conventions & Code Layout

1. **Types & Protocols:** UpperCamelCase (`AudioCaptureManager`, `TranscriptionProvider`).
2. **Variables & Functions:** lowerCamelCase (`startStreaming()`, `currentMeetingID`).
3. **Constants & Enums:** lowerCamelCase (`case capturing`, `case permissionDenied`).
4. **Files:** Named identically to the primary type declared (`AudioMixer.swift`).
5. **File Header:** Standard concise header; no boilerplate comments.

---

## 5. Logging Standards (`OSLog`)

Use unified Apple logging via `os.Logger`. Never use plain `print()` statements in production code.

```swift
import OSLog

public enum AppLog {
    public static let audio = Logger(subsystem: "com.aura.meetingai", category: "audio")
    public static let transcription = Logger(subsystem: "com.aura.meetingai", category: "transcription")
    public static let ai = Logger(subsystem: "com.aura.meetingai", category: "ai")
    public static let data = Logger(subsystem: "com.aura.meetingai", category: "data")
}

// Usage:
AppLog.audio.info("Starting audio capture with device: \(deviceName, privacy: .public)")
// Sensitive data (e.g. transcript text) is never logged
```
