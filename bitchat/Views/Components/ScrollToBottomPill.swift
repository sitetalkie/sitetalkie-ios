//
// ScrollToBottomPill.swift
// bitchat
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import SwiftUI

/// A floating pill button that appears when the user scrolls up and new messages arrive
struct ScrollToBottomPill: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text("↓")
                    .font(.system(size: 16, weight: .medium))
                Text("New messages")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(Color(red: 0.102, green: 0.110, blue: 0.125)) // #1A1C20
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color(red: 0.910, green: 0.588, blue: 0.047)) // #E8960C amber
                    .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
