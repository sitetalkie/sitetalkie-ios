//
// LocationDropCardView.swift
// bitchat
//
// Styled card for rendering a [LOCATION_DROP:] message in chat.
//

import SwiftUI

#if os(iOS)

struct LocationDropCardView: View {
    let drop: LocationDrop
    let isSelf: Bool
    let timestamp: String

    // Design system
    private let amber = Color(red: 0.910, green: 0.588, blue: 0.047)           // #E8960C
    private let emergencyRed = Color(red: 1.0, green: 0.271, blue: 0.227)      // #FF453A
    private let labelColor = Color(red: 0.353, green: 0.369, blue: 0.400)      // #5A5E66
    private let cardBackground = Color(red: 0.102, green: 0.110, blue: 0.125)  // #1A1C20
    private let textPrimary = Color(red: 0.941, green: 0.941, blue: 0.941)     // #F0F0F0

    private var accentColor: Color { drop.isEmergency ? emergencyRed : amber }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header bar
            HStack {
                if drop.isEmergency {
                    Text("\u{26A0}\u{FE0F} \u{1F6A8} HELP NEEDED")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(emergencyRed)
                        .textCase(.uppercase)
                } else {
                    Text("\u{1F4CD} LOCATION DROP")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(amber)
                        .textCase(.uppercase)
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(accentColor.opacity(0.12))

            VStack(alignment: .leading, spacing: 8) {
                // Sender line (incoming only)
                if !isSelf {
                    senderLine
                }

                // Fields
                fieldRow(icon: "\u{1F3E2}", label: "FLOOR", value: drop.floor)
                fieldRow(icon: "\u{1F4D0}", label: "ZONE", value: drop.zone)

                if let landmark = drop.nearLandmark, !landmark.isEmpty {
                    fieldRow(icon: "\u{1F4CC}", label: "NEAR", value: landmark)
                }

                if let msg = drop.message, !msg.isEmpty {
                    fieldRow(
                        icon: "\u{1F4AC}",
                        label: "MESSAGE",
                        value: msg,
                        valueColor: drop.isEmergency ? emergencyRed : textPrimary
                    )
                }

                // Photo indicator
                if drop.hasPhoto {
                    HStack(spacing: 6) {
                        Text("\u{1F4F7}")
                            .font(.system(size: 12))
                        Text("Photo attached")
                            .font(.system(size: 11))
                            .foregroundColor(labelColor)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.04))
                    )
                }

                // Timestamp
                Text(timestamp)
                    .font(.system(size: 9))
                    .foregroundColor(labelColor)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(12)
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(accentColor, lineWidth: drop.isEmergency ? 1.5 : 1)
        )
        .frame(maxWidth: 300, alignment: isSelf ? .trailing : .leading)
        .frame(maxWidth: .infinity, alignment: isSelf ? .trailing : .leading)
        .onAppear {
            if drop.isEmergency && !isSelf {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.warning)
            }
        }
    }

    // MARK: - Sender Line

    private var senderLine: some View {
        HStack(spacing: 0) {
            Text(drop.senderName)
                .font(.system(size: 11, weight: .bold))
            if let trade = drop.senderTrade, !trade.isEmpty {
                Text(" \u{00B7} \(trade)")
                    .font(.system(size: 11))
            }
        }
        .foregroundColor(accentColor)
    }

    // MARK: - Field Row

    private func fieldRow(icon: String, label: String, value: String, valueColor: Color? = nil) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text(icon)
                .font(.system(size: 12))
                .frame(width: 18, alignment: .center)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(labelColor)
                    .tracking(0.5)
                Text(value)
                    .font(.system(size: 13))
                    .foregroundColor(valueColor ?? textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Decoder Helper

extension LocationDropCardView {
    /// Attempt to decode a LocationDrop from a tagged message string.
    /// Expected format: [LOCATION_DROP:{json}]
    static func decode(from content: String) -> LocationDrop? {
        let prefix = "[LOCATION_DROP:"
        let suffix = "]"
        guard content.hasPrefix(prefix), content.hasSuffix(suffix) else { return nil }
        let jsonStart = content.index(content.startIndex, offsetBy: prefix.count)
        let jsonEnd = content.index(content.endIndex, offsetBy: -suffix.count)
        guard jsonStart < jsonEnd else { return nil }
        let json = String(content[jsonStart..<jsonEnd])
        guard let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(LocationDrop.self, from: data)
    }
}

#endif
