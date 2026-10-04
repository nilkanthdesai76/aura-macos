//
//  InMeetingChatViewModel.swift
//  Granola
//

import Foundation
import SwiftUI

public struct ChatMessage: Identifiable, Equatable {
    public let id = UUID()
    public let isUser: Bool
    public let text: String
    public let timestamp: Date = Date()
}

@MainActor
@Observable
public final class InMeetingChatViewModel {
    public var messages: [ChatMessage] = []
    public var inputText: String = ""
    public var isProcessing: Bool = false
    
    private let aiService: AIService
    
    public init(aiService: AIService = DependencyContainer.shared.aiService) {
        self.aiService = aiService
    }
    
    public func sendQuestion(meeting: Meeting) async {
        let question = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty else { return }
        
        messages.append(ChatMessage(isUser: true, text: question))
        inputText = ""
        isProcessing = true
        
        do {
            let answer = try await aiService.answerMeetingQuestion(
                question: question,
                userNotes: meeting.userNotes,
                segments: meeting.segments
            )
            messages.append(ChatMessage(isUser: false, text: answer))
        } catch {
            messages.append(ChatMessage(isUser: false, text: "Error: \(error.localizedDescription)"))
        }
        
        isProcessing = false
    }
}
