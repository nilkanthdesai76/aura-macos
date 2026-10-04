//
//  SourceLinkedBadgeView.swift
//  Granola
//

import SwiftUI

public struct SourceLinkedBadgeView: View {
    public let sourceSegmentIDs: [UUID]
    public var onSelect: ((UUID) -> Void)?
    
    public init(sourceSegmentIDs: [UUID], onSelect: ((UUID) -> Void)? = nil) {
        self.sourceSegmentIDs = sourceSegmentIDs
        self.onSelect = onSelect
    }
    
    public var body: some View {
        if let firstID = sourceSegmentIDs.first {
            Button {
                onSelect?(firstID)
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: "link")
                        .font(.system(size: 8))
                    Text("Source")
                        .font(.system(size: 10, weight: .medium))
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(Color.secondary.opacity(0.12))
                )
                .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("Click to view exact transcript source segment")
        }
    }
}
