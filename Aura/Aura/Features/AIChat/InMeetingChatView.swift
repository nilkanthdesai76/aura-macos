//
//  InMeetingChatView.swift
//  Granola
//

import SwiftUI

public struct InMeetingChatView: View {
    public let meeting: Meeting
    @State private var viewModel = InMeetingChatViewModel()
    
    public init(meeting: Meeting) {
        self.meeting = meeting
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Label("Ask On-Device AI", systemImage: "sparkles")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.purple)
                
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Messages List
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        if viewModel.messages.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Ask anything about this meeting:")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                QuickPromptChip(text: "What were the main decisions?") {
                                    viewModel.inputText = "What were the main decisions?"
                                    Task { await viewModel.sendQuestion(meeting: meeting) }
                                }
                                
                                QuickPromptChip(text: "List all action items with assignees") {
                                    viewModel.inputText = "List all action items with assignees"
                                    Task { await viewModel.sendQuestion(meeting: meeting) }
                                }
                                
                                QuickPromptChip(text: "Draft a follow-up email") {
                                    viewModel.inputText = "Draft a crisp follow-up email based on decisions"
                                    Task { await viewModel.sendQuestion(meeting: meeting) }
                                }
                            }
                            .padding(.top, 10)
                        } else {
                            ForEach(viewModel.messages) { msg in
                                HStack {
                                    if msg.isUser { Spacer() }
                                    
                                    Text(msg.text)
                                        .font(.system(size: 12))
                                        .padding(10)
                                        .foregroundColor(msg.isUser ? .white : .primary)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(msg.isUser ? Color.accentColor : Color(NSColor.textBackgroundColor))
                                        )
                                        .textSelection(.enabled)
                                    
                                    if !msg.isUser { Spacer() }
                                }
                                .id(msg.id)
                            }
                        }
                        
                        if viewModel.isProcessing {
                            HStack(spacing: 6) {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Thinking on-device...")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(12)
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    if let lastID = viewModel.messages.last?.id {
                        withAnimation { proxy.scrollTo(lastID, anchor: .bottom) }
                    }
                }
            }
            
            Divider()
            
            // Input Bar
            HStack(spacing: 8) {
                TextField("Ask about this meeting...", text: $viewModel.inputText)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12))
                    .onSubmit {
                        Task { await viewModel.sendQuestion(meeting: meeting) }
                    }
                
                Button {
                    Task { await viewModel.sendQuestion(meeting: meeting) }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.inputText.isEmpty || viewModel.isProcessing)
            }
            .padding(10)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

private struct QuickPromptChip: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(NSColor.textBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
