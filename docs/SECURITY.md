# Security & Privacy Architecture (SECURITY.md)

## Guiding Principle: Radical Data Minimization & Privacy-by-Design

Meeting conversations contain the most sensitive corporate, technical, and personal communications. This application is architected from the ground up to ensure privacy, zero unauthorized retention, and enterprise-grade security.

---

## 1. Zero Audio Retention Policy

### 1.1 In-Memory Ephemeral Audio Pipeline
* **Default Setting:** `AudioRetentionPolicy.shouldPersistAudio = false`.
* **Mechanism:** Audio buffers captured from the microphone and system audio loopback are held exclusively in volatile RAM within a small circular ring buffer (max 5 seconds of PCM frames).
* **Immediate Disposal:** Once audio frames are encoded and streamed to the transcription provider, the memory is zeroed (`memset`) and deallocated.
* **No Disk Caching:** At no point during standard operation is raw uncompressed or compressed audio written to `tmp`, `Caches`, or permanent disk storage.

```swift
public protocol AudioRetentionPolicy {
    var shouldPersistAudio: Bool { get }
}

public struct DefaultPrivacyPolicy: AudioRetentionPolicy {
    public let shouldPersistAudio: Bool = false
}
```

---

## 2. Secure Credential & Secret Management

* **No Hardcoded Keys:** Secrets, API keys, OAuth tokens, and encryption salts are strictly prohibited from Swift source files, `UserDefaults`, `Info.plist`, or Git history.
* **Apple Keychain Services:** All API keys (OpenAI, Anthropic, Deepgram) and user tokens are stored using the native macOS Keychain (`Security.framework`) with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`.

```swift
import Foundation
import Security

public enum KeychainManager {
    public static func save(key: String, data: String) throws {
        guard let dataBlob = data.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: dataBlob,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.saveFailed(status) }
    }
}
```

---

## 3. macOS System Permissions & Entitlements

The application requests only the minimum required macOS permissions. Permission explanations are transparent and human-readable.

### 3.1 Required Entitlements
* **Microphone Access:** `com.apple.security.device.audio-input`
* **Network Client (Outgoing):** `com.apple.security.network.client`
* **App Sandbox:** Configured with specific hardware/network exceptions.

### 3.2 Info.plist Usage Descriptions
* `NSMicrophoneUsageDescription`: *"Aura needs microphone access to transcribe your spoken voice during meetings."*
* `NSSystemAudioRecordingUsageDescription`: *"Aura captures system audio from meeting participants to generate transcripts."*
* `NSCalendarsUsageDescription`: *"Aura accesses your calendar to display upcoming meetings and attendee lists."*

---

## 4. Network Security & LLM Data Protection

### 4.1 In-Transit Encryption
* All network communication with cloud transcription engines and LLM providers is enforced over **TLS 1.3 / HTTPS** and **WSS (Secure WebSockets)**.

### 4.2 LLM Data Handling Agreement
* Third-party AI providers (Anthropic, OpenAI) are accessed via enterprise zero-data-retention API endpoints.
* Prompts specify that customer conversation data must not be stored on model provider servers or used to train public foundation models.

---

## 5. Security & Privacy Audit Checklist

| Item | Requirement | Verification Method |
| :--- | :--- | :--- |
| **Audio Disk Cleanliness** | No `.wav`, `.m4a`, or `.pcm` files saved to disk | Automated test inspecting sandbox temp directories |
| **Log Sanitization** | `OSLog` calls must never log transcript text or tokens | Code review & regex lint check |
| **Keychain Isolation** | Keys accessible only when device is unlocked | Keychain query attribute verification |
| **Permission Transparency**| App provides direct links to macOS Privacy Settings | UI test on permission rejection |
| **Local Data Deletion** | "Delete Meeting" purges notes, summaries, and transcripts | SwiftData cascade deletion test |
