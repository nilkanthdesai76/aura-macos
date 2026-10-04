# Native macOS Design System (DESIGN_SYSTEM.md)

## Design Philosophy: Native, Editorial, Distraction-Free

The application embodies the essence of a modern native macOS utility—clean, whisper-quiet, incredibly fast, and tightly integrated with the macOS desktop environment. It rejects electron/web styling in favor of Apple Human Interface Guidelines (HIG) with subtle editorial typography.

---

## 1. Visual Hierarchy & Window Layout

The main application window utilizes `NavigationSplitView` with a 3-column architecture (Sidebar $\rightarrow$ Content List $\rightarrow$ Detail Workspace), with an optional collapsible Inspector for AI Chat.

```
┌─────────────────┬──────────────────────┬────────────────────────────────────────────────────────┐
│    SIDEBAR      │     MEETING LIST     │                  ACTIVE WORKSPACE                      │
│ (220px fixed)   │    (280px fixed)     │                   (Flexible width)                     │
├─────────────────┼──────────────────────┼────────────────────────────────────────────────────────┤
│ ❖ All Meetings  │ TODAY                │ Product Architecture Sync             [ Export ] [ ⋯ ] │
│ 📅 Upcoming     │ • Product Sync  10:00│ September 29, 2026 • 45m • 4 Participants              │
│ ⭐ Starred      │ • 1:1 with Sarah 14:00│ ────────────────────────────────────────────────────── │
│ 🏷️ Tags         │                      │ [ My Notes ]  [ Enhanced Notes ★ ]  [ Transcript ]    │
│                 │ YESTERDAY            │                                                        │
│ RECIPES         │ • Sprint Planning    │ ## Key Decisions                                       │
│ ⚙️ Engineering  │ • Design Critique    │ - Approved SwiftUI native macOS architecture          │
│ 💼 Sales (MEDD) │                      │   [ Source 04:12 ]                                     │
│ 👤 1-on-1       │                      │                                                        │
│                 │                      │ ## Action Items                                        │
│ ⚙️ Settings     │                      │ [ ] Implement ScreenCaptureKit tap (@Nilkanth)        │
│                 │                      │     Due: Friday  [ Source 12:45 ]                      │
└─────────────────┴──────────────────────┴────────────────────────────────────────────────────────┘
```

---

## 2. Typography System

We utilize Apple's system font families (`SF Pro`, `SF Pro Rounded`, `SF Mono`, and `New York` for editorial headings).

| Style | Font Family | Size | Weight | Usage |
| :--- | :--- | :--- | :--- | :--- |
| **Display Large** | SF Pro Display | 24pt | Bold | Major view titles, Onboarding |
| **Headline / H1** | New York (Editorial) / SF Pro | 18pt | Semibold | Meeting titles, Section headers |
| **Subheadline / H2**| SF Pro | 14pt | Medium | Subheaders, Discussion point topics |
| **Body Text** | SF Pro Text | 13pt | Regular | Primary notes editor, transcript body |
| **Secondary Body** | SF Pro Text | 11pt | Regular | Timestamps, participant lists, meta |
| **Code / Monospace**| SF Mono | 12pt | Regular | Transcripts, keyboard shortcuts, logs |

---

## 3. Color Palette & Semantic Tokens

The app fully adapts to macOS **Light Mode**, **Dark Mode**, and **Accent Color** preferences.

```swift
extension Color {
    // Canvas & Surfaces
    static let surfaceBackground = Color(NSColor.windowBackgroundColor)
    static let surfaceSidebar = Color(NSColor.controlBackgroundColor)
    static let surfaceCard = Color(NSColor.underPageBackgroundColor)
    
    // Status Indicators
    static let recordingActive = Color.red
    static let transcribingPulse = Color.orange
    static let aiProcessing = Color.purple
    static let statusSuccess = Color.green
    
    // Semantic Accents
    static let actionItemPill = Color.blue.opacity(0.12)
    static let decisionPill = Color.green.opacity(0.12)
    static let sourceBadge = Color.secondary.opacity(0.15)
}
```

---

## 4. Key UI Components & Atoms

### 4.1 Audio Level Meter (Low-CPU Canvas)
* During live recording, a dual-bar horizontal amplitude meter visually represents **Microphone** and **System Audio** levels.
* Built using SwiftUI `Canvas` or lightweight CoreGraphics shapes (rendered at 30Hz instead of 120Hz to preserve battery).
* Includes a pulsing recording dot with live meeting duration elapsed (`00:14:22`).

### 4.2 Three-Tier Workspace Tabs
* **Segmented Control** at the top of the meeting detail view:
  * `[ My Notes ]`: Clean editable Markdown text canvas.
  * `[ Enhanced Notes ★ ]`: Rich cards, formatted decisions, checklists, and highlighted quotes.
  * `[ Transcript ]`: Diarized chat-style stream with timestamps and speaker chips.

### 4.3 Source-Link Pill Button
* Every extracted decision and action item displays a discrete `[ 🔍 04:12 ]` source badge.
* Clicking this badge opens the Transcript tab, scrolls smoothly to the target segment, and flashes a subtle golden highlight for 1.5 seconds.

### 4.4 Command Palette (`⌘K`)
* Spotlight-style floating modal window.
* Instant keyboard search across all meeting titles, notes, and actions.
* Actions: *"Start New Meeting"*, *"Change Audio Input"*, *"Export to Markdown"*, *"Apply Engineering Recipe"*.

### 4.5 Native Menu Bar Companion (`MenuBarExtra`)
* Status item in the macOS menu bar:
  * Idle state: Subtle wave icon `🎙️`.
  * Active state: Pulsing red dot `● REC (12:45)`.
* Menu dropdown:
  * **Quick Start:** 1-Click "Start Meeting Now"
  * **Next Meeting:** Displays upcoming calendar event with a "Join & Record" button.
  * **Recent Notes:** Quick links to the last 3 meetings.

---

## 5. Keyboard Navigation & Shortcuts

| Shortcut | Action | Scope |
| :--- | :--- | :--- |
| `⌘ + K` | Open Command Palette | Global |
| `⌘ + Enter` | Start / Stop Meeting Capture | Global |
| `⌘ + 1` | Navigate to Home / Upcoming | App Window |
| `⌘ + 2` | Navigate to All Meetings History | App Window |
| `⌘ + F` | Search within current transcript/notes | Meeting Detail |
| `⌘ + Shift + E` | Switch to Enhanced Notes Tab | Meeting Detail |
| `⌘ + Shift + T` | Switch to Transcript Tab | Meeting Detail |
| `⌘ + Shift + N` | Switch to My Notes Tab | Meeting Detail |
| `Esc` | Dismiss modals, Command Palette, or Search | Overlays |
