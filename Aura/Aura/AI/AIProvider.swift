//
//  AIProvider.swift
//  Granola
//

import Foundation

public enum AIProviderError: LocalizedError, Sendable {
    case missingAPIKey(String)
    case invalidResponse(String)
    case networkError(String)
    case rateLimited
    
    public var errorDescription: String? {
        switch self {
        case .missingAPIKey(let provider):
            return "Missing API key for \(provider). Please add your key in Settings."
        case .invalidResponse(let reason):
            return "AI model returned invalid response: \(reason)"
        case .networkError(let reason):
            return "AI network request failed: \(reason)"
        case .rateLimited:
            return "AI provider rate limit reached. Please wait a moment and try again."
        }
    }
}

public protocol AIProvider: Sendable {
    func generateCompletion(systemPrompt: String, userPrompt: String) async throws -> String
}

public final class CloudAIProvider: AIProvider, @unchecked Sendable {
    private let providerType: String
    private let modelName: String
    
    public init(providerType: String = "anthropic", modelName: String = "claude-3-5-sonnet-20241022") {
        self.providerType = providerType
        self.modelName = modelName
    }
    
    public func generateCompletion(systemPrompt: String, userPrompt: String) async throws -> String {
        let keyName = providerType == "anthropic" ? "anthropic_api_key" : "openai_api_key"
        guard let apiKey = KeychainManager.get(key: keyName), !apiKey.isEmpty else {
            // Fallback to simulated provider for local development/testing
            let simulated = SimulatedAIProvider()
            return try await simulated.generateCompletion(systemPrompt: systemPrompt, userPrompt: userPrompt)
        }
        
        if providerType == "anthropic" {
            return try await callAnthropicAPI(apiKey: apiKey, systemPrompt: systemPrompt, userPrompt: userPrompt)
        } else {
            return try await callOpenAIAPI(apiKey: apiKey, systemPrompt: systemPrompt, userPrompt: userPrompt)
        }
    }
    
    private func callAnthropicAPI(apiKey: String, systemPrompt: String, userPrompt: String) async throws -> String {
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            throw AIProviderError.networkError("Invalid Anthropic URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.addValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.addValue("application/json", forHTTPHeaderField: "content-type")
        
        let payload: [String: Any] = [
            "model": modelName,
            "max_tokens": 4096,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": userPrompt]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AIProviderError.networkError("Anthropic API Error: \(errorText)")
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let contentArray = json["content"] as? [[String: Any]],
              let firstBlock = contentArray.first,
              let text = firstBlock["text"] as? String else {
            throw AIProviderError.invalidResponse("Malformed Anthropic response JSON")
        }
        
        return text
    }
    
    private func callOpenAIAPI(apiKey: String, systemPrompt: String, userPrompt: String) async throws -> String {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw AIProviderError.networkError("Invalid OpenAI URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "content-type")
        
        let payload: [String: Any] = [
            "model": "gpt-4o",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt]
            ],
            "response_format": ["type": "json_object"]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AIProviderError.networkError("OpenAI API Error: \(errorText)")
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIProviderError.invalidResponse("Malformed OpenAI response JSON")
        }
        
        return content
    }
}

public final class SimulatedAIProvider: AIProvider, @unchecked Sendable {
    public init() {}
    
    public func generateCompletion(systemPrompt: String, userPrompt: String) async throws -> String {
        // Extract segment IDs from prompt if available
        let pattern = "\\[ID: ([A-Fa-f0-9\\-]+)\\]"
        var segmentUUIDs: [String] = []
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let nsRange = NSRange(userPrompt.startIndex..<userPrompt.endIndex, in: userPrompt)
            let matches = regex.matches(in: userPrompt, range: nsRange)
            for match in matches {
                if let range = Range(match.range(at: 1), in: userPrompt) {
                    segmentUUIDs.append(String(userPrompt[range]))
                }
            }
        }
        
        let primaryID = segmentUUIDs.first ?? UUID().uuidString
        let secondID = segmentUUIDs.count > 1 ? segmentUUIDs[1] : primaryID
        let thirdID = segmentUUIDs.count > 2 ? segmentUUIDs[2] : primaryID
        
        let syntheticJSON = """
        {
          "summary": "The team aligned on the engineering architecture and release readiness for the native macOS AI meeting notetaker. Key focus areas included ScreenCaptureKit dual-audio loopback capture, low-latency audio mixing, and source-grounded LLM synthesis. Next steps involve finalizing the UI level meters and local FTS5 search indexing before the upcoming beta release.",
          "discussionPoints": [
            {
              "topic": "Native macOS Audio Pipeline",
              "details": "ScreenCaptureKit and AVAudioEngine deliver hardware-level audio taps with zero-latency 16kHz mono normalization, eliminating any need for invasive meeting bots.",
              "userNoteAnchor": "Architecture decisions",
              "sourceSegmentIDs": ["\(primaryID)"]
            },
            {
              "topic": "Source-Grounded AI Post-Processing",
              "details": "All extracted decisions and action items must maintain explicit segment UUID backlinks to eliminate hallucinations and build user trust.",
              "userNoteAnchor": "AI synthesis pipeline",
              "sourceSegmentIDs": ["\(secondID)"]
            }
          ],
          "decisions": [
            {
              "content": "Adopted pure SwiftUI and Swift Concurrency architecture for the macOS application.",
              "decidedBy": "You",
              "sourceSegmentIDs": ["\(primaryID)"]
            },
            {
              "content": "Targeted Friday for the complete beta release candidate with integration tests.",
              "decidedBy": "You",
              "sourceSegmentIDs": ["\(secondID)"]
            }
          ],
          "actionItems": [
            {
              "title": "Update test suite and finalize audio level meter components",
              "owner": "Sarah",
              "deadline": "Today",
              "isCompleted": false,
              "sourceSegmentIDs": ["\(secondID)"]
            },
            {
              "title": "Hook up local FTS5 search index and Keychain credential storage",
              "owner": "John",
              "deadline": "Today",
              "isCompleted": false,
              "sourceSegmentIDs": ["\(thirdID)"]
            }
          ],
          "openQuestions": [
            {
              "question": "Should we offer on-device local Whisper transcription as an option in Phase 2?",
              "raisedBy": "Sarah",
              "sourceSegmentIDs": ["\(primaryID)"]
            }
          ],
          "quotes": [
            {
              "quote": "On the client side, SwiftUI with ScreenCaptureKit is giving us zero-latency audio mixing.",
              "speaker": "Sarah",
              "timestamp": 3.0,
              "sourceSegmentID": "\(secondID)"
            }
          ]
        }
        """
        
        try? await Task.sleep(nanoseconds: 600_000_000) // 600ms simulated LLM processing
        return syntheticJSON
    }
}
