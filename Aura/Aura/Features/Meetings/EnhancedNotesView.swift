//
//  EnhancedNotesView.swift
//  Granola
//

import SwiftUI

public struct EnhancedNotesView: View {
    public let summary: MeetingSummary?
    public var onJumpToSegment: ((UUID) -> Void)?
    
    public init(summary: MeetingSummary?, onJumpToSegment: ((UUID) -> Void)? = nil) {
        self.summary = summary
        self.onJumpToSegment = onJumpToSegment
    }
    
    public var body: some View {
        if let summary = summary {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Executive Summary
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Executive Summary", systemImage: "sparkles")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.purple)
                        
                        Text(summary.summary)
                            .font(.system(size: 14, weight: .regular))
                            .lineSpacing(4)
                            .foregroundColor(.primary)
                            .textSelection(.enabled)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.purple.opacity(0.06))
                    )
                    
                    // Key Decisions
                    if !summary.decisions.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Key Decisions", systemImage: "checkmark.seal.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.green)
                            
                            VStack(spacing: 8) {
                                ForEach(summary.decisions) { decision in
                                    HStack(alignment: .top, spacing: 10) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 13))
                                            .foregroundColor(.green)
                                            .padding(.top, 2)
                                        
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(decision.content)
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundColor(.primary)
                                            
                                            if let decidedBy = decision.decidedBy {
                                                Text("Decided by: \(decidedBy)")
                                                    .font(.system(size: 11))
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        SourceLinkedBadgeView(
                                            sourceSegmentIDs: decision.sourceSegmentIDs,
                                            onSelect: onJumpToSegment
                                        )
                                    }
                                    .padding(10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(NSColor.textBackgroundColor))
                                    )
                                }
                            }
                        }
                    }
                    
                    // Action Items
                    if !summary.actionItems.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Action Items", systemImage: "checklist")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.blue)
                            
                            VStack(spacing: 8) {
                                ForEach(summary.actionItems) { item in
                                    HStack(alignment: .top, spacing: 10) {
                                        Image(systemName: item.isCompleted ? "checkmark.square.fill" : "square")
                                            .font(.system(size: 14))
                                            .foregroundColor(item.isCompleted ? .green : .secondary)
                                            .padding(.top, 2)
                                        
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(item.title)
                                                .font(.system(size: 13, weight: .medium))
                                                .strikethrough(item.isCompleted)
                                            
                                            HStack(spacing: 8) {
                                                if let owner = item.owner {
                                                    Label(owner, systemImage: "person.circle")
                                                        .font(.system(size: 11))
                                                        .foregroundColor(.secondary)
                                                }
                                                if let deadline = item.deadline {
                                                    Label(deadline, systemImage: "calendar")
                                                        .font(.system(size: 11))
                                                        .foregroundColor(.orange)
                                                }
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        SourceLinkedBadgeView(
                                            sourceSegmentIDs: item.sourceSegmentIDs,
                                            onSelect: onJumpToSegment
                                        )
                                    }
                                    .padding(10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(NSColor.textBackgroundColor))
                                    )
                                }
                            }
                        }
                    }
                    
                    // Discussion Points
                    if !summary.discussionPoints.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Discussion Breakdown", systemImage: "text.bubble")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.primary)
                            
                            VStack(spacing: 12) {
                                ForEach(summary.discussionPoints) { point in
                                    VStack(alignment: .leading, spacing: 6) {
                                        HStack {
                                            Text(point.topic)
                                                .font(.system(size: 13, weight: .semibold))
                                            
                                            Spacer()
                                            
                                            SourceLinkedBadgeView(
                                                sourceSegmentIDs: point.sourceSegmentIDs,
                                                onSelect: onJumpToSegment
                                            )
                                        }
                                        
                                        Text(point.details)
                                            .font(.system(size: 13))
                                            .foregroundColor(.secondary)
                                            .lineSpacing(3)
                                    }
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(NSColor.controlBackgroundColor))
                                    )
                                }
                            }
                        }
                    }
                    
                    // Verbatim Quotes
                    if !summary.quotes.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Key Quotes", systemImage: "quote.opening")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.secondary)
                            
                            VStack(spacing: 8) {
                                ForEach(summary.quotes) { q in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\"\(q.quote)\"")
                                            .font(.system(size: 13, weight: .regular, design: .serif))
                                            .italic()
                                        
                                        HStack {
                                            Text("— \(q.speaker)")
                                                .font(.system(size: 11, weight: .medium))
                                                .foregroundColor(.secondary)
                                            Spacer()
                                            SourceLinkedBadgeView(
                                                sourceSegmentIDs: [q.sourceSegmentID],
                                                onSelect: onJumpToSegment
                                            )
                                        }
                                    }
                                    .padding(10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(NSColor.controlBackgroundColor).opacity(0.6))
                                    )
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
        } else {
            VStack(spacing: 10) {
                Spacer()
                Image(systemName: "sparkles")
                    .font(.system(size: 36))
                    .foregroundColor(.secondary.opacity(0.5))
                Text("No AI synthesis available for this meeting.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
