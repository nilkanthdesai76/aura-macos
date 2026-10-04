//
//  NotesEditorView.swift
//  Granola
//

import SwiftUI

public struct NotesEditorView: View {
    @Binding public var text: String
    public var placeholder: String
    
    public init(
        text: Binding<String>,
        placeholder: String = "Jot down rough notes, decisions, or focus questions during the meeting..."
    ) {
        self._text = text
        self.placeholder = placeholder
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("My Notes", systemImage: "note.text")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("AI priority context")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 2)
            
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary.opacity(0.6))
                        .padding(.top, 8)
                        .padding(.leading, 5)
                        .allowsHitTesting(false)
                }
                
                TextEditor(text: $text)
                    .font(.system(size: 14, weight: .regular))
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(NSColor.textBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
            )
        }
    }
}
