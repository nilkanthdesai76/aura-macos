# Aura — Native macOS AI Meeting Memory & Notetaker

[![Platform](https://img.shields.io/badge/Platform-macOS%2014.0%2B-blue.svg)](https://developer.apple.com/macos)
[![Swift 5.9+](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![CI](https://github.com/nilkanthdesai76/aura-macos/actions/workflows/ci.yml/badge.svg)](https://github.com/nilkanthdesai76/aura-macos/actions/workflows/ci.yml)

**Aura** is a native, fast, privacy-first macOS application that captures meeting audio (Microphone + System Audio via ScreenCaptureKit loopback), provides continuous real-time speech-to-text transcription, allows taking shorthand notes, and transforms conversations into structured, source-grounded meeting knowledge using on-device and local AI.

![Aura Architecture](assets/aura_macos_diagram.svg)

---

## ✨ Features

- 🎙️ **Dual-Stream Audio Capture** — Simultaneously records your microphone (`AVAudioEngine`) and system audio (`ScreenCaptureKit` loopback) without virtual audio drivers or third-party kernel extensions.
- ⚡ **Continuous Real-Time Transcription** — Live streaming transcription supporting on-device Apple Speech framework and local Whisper models with automatic chunking and speaker diarization.
- 📝 **Live Meeting Notepad** — Side-by-side note taking with real-time transcript synchronization and instant bookmarking.
- 🧠 **Source-Grounded AI Synthesis** — Generates executive summaries, key decisions, and action item checklists with direct timestamp citations back to the verbatim audio transcript.
- 🔒 **Zero-Retention Privacy** — Audio is processed in ephemeral circular ring buffers and immediately purged from memory once transcribed. No audio is ever uploaded to unencrypted third parties.
- 🔍 **Full-Text SQLite FTS5 Search** — Lightning-fast, instant search across historical meeting transcripts, summaries, and action items.
- 🧭 **Menu Bar Companion (`MenuBarExtra`)** — Global keyboard shortcuts (`⌘Enter`) and quick menu bar status control to start or stop meetings in one click.

---

## 🏗️ Architecture

| Layer | Technologies | Responsibilities |
| :--- | :--- | :--- |
| **Audio Subsystem** | `ScreenCaptureKit`, `AVAudioEngine`, `AVAudioPCMBuffer` | Low-latency audio capture, format normalization (16kHz 16-bit mono PCM), and circular buffering. |
| **Speech Engine** | `Speech.framework`, `StreamingTranscriber` | Continuous real-time voice activity detection (VAD), interim token streaming, and speaker tagging. |
| **AI Intelligence** | CoreML, Local LLMs, `AIService` | Source-linked meeting synthesis, action item extraction, and interactive meeting Q&A. |
| **Storage & Security** | `SwiftData`, SQLite FTS5, `Keychain` | Local meeting archive, fast full-text indexing, and secure token management. |
| **UI Presentation** | SwiftUI, AppKit | 3-column macOS desktop interface, live wave visualizer, and menu bar extra. |

---

## 🛠️ Requirements & Building

- **Operating System:** macOS 14.0 (Sonoma) or macOS 15.0 (Sequoia)
- **Xcode:** 15.4+ or Xcode 16+
- **Architecture:** Apple Silicon (M1/M2/M3/M4) recommended

### Build via Command Line

```bash
cd Aura
xcodebuild -project Aura.xcodeproj -scheme Aura -destination 'platform=macOS' -configuration Debug build CODE_SIGNING_ALLOWED=NO
```

---

## 📚 Detailed Documentation

All engineering specifications and architectural blueprints are available in [`docs/`](docs/):

- [Architecture Guide](docs/ARCHITECTURE.md)
- [Product Requirements (PRD)](docs/PRD.md)
- [Design System](docs/DESIGN_SYSTEM.md)
- [Security & Zero-Retention Model](docs/SECURITY.md)
- [AI Prompts & Agent Contracts](docs/AGENTS.md)
- [Coding Guidelines & Patterns](docs/CODE_STYLE.md)

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
