//
// SnagCardView.swift
// bitchat
//
// In-chat card for [SNAG:...] messages on #defects channel.
// Styled as a compact card with priority-colored left border — less dramatic than SiteAlertBannerView.
//

import SwiftUI

#if os(iOS)

struct SnagCardView: View {
    let snag: SnagMessage
    let senderName: String
    let timestamp: String

    // Design system
    private let cardColor = Color(red: 0.102, green: 0.110, blue: 0.125)       // #1A1C20
    private let textPrimary = Color(red: 0.941, green: 0.941, blue: 0.941)     // #F0F0F0
    private let textSecondary = Color(red: 0.541, green: 0.557, blue: 0.588)   // #8A8E96

    var body: some View {
        HStack(spacing: 0) {
            // Priority-colored left border
            Rectangle()
                .fill(snag.priority.color)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 6) {
                // Top row: priority pill + floor + trade
                HStack(spacing: 8) {
                    // Priority pill
                    Text(snag.priority.label.uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(snag.priority.color)
                        )

                    if let floorLabel = snag.floorLabel {
                        Text(floorLabel)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(textSecondary)
                    }

                    if let trade = snag.trade {
                        Text(trade)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(snag.priority.color.opacity(0.85))
                    }

                    Spacer()
                }

                // Title
                Text(snag.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(textPrimary)

                // Description
                if !snag.detail.isEmpty {
                    Text(snag.detail)
                        .font(.system(size: 14))
                        .foregroundColor(textSecondary)
                }

                // Photo indicator
                if snag.hasPhoto {
                    HStack(spacing: 4) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 11))
                        Text("Photo attached")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(textSecondary.opacity(0.8))
                }

                // Sender + timestamp
                HStack(spacing: 6) {
                    Text(senderName)
                        .font(.system(size: 12))
                        .foregroundColor(textSecondary)

                    Text("\u{00B7}")
                        .font(.system(size: 12))
                        .foregroundColor(textSecondary)

                    Text(timestamp)
                        .font(.system(size: 12))
                        .foregroundColor(textSecondary)
                }
            }
            .padding(10)
        }
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(cardColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(snag.priority.color.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 8)
    }
}

#endif
