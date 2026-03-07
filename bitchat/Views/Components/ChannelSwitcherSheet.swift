//
// ChannelSwitcherSheet.swift
// bitchat
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import SwiftUI

enum ChannelType: String, Identifiable {
    case site = "#site"
    case general = "#general"
    case defects = "#defects"
    case deliveries = "#deliveries"

    var id: String { rawValue }

    var isPublic: Bool { true }

    var displayLabel: String? {
        if self == .site {
            return "Public"
        }
        return nil
    }

    var subtitle: String {
        switch self {
        case .site: return "Public chat for your site"
        case .general: return "General discussion"
        case .defects: return "Report and track defects"
        case .deliveries: return "Delivery coordination"
        }
    }

    /// The short tag name used in [CH:xxx] wire prefix (nil for #site — no tag needed)
    var channelTag: String? {
        switch self {
        case .site: return nil
        case .general: return "general"
        case .defects: return "defects"
        case .deliveries: return "deliveries"
        }
    }

    /// Build from a parsed tag string (e.g. "general" → .general)
    static func fromTag(_ tag: String) -> ChannelType? {
        switch tag.lowercased() {
        case "general": return .general
        case "defects": return .defects
        case "deliveries": return .deliveries
        default: return nil
        }
    }

    /// Prepend [CH:xxx] to message content for non-site channels
    func taggedContent(_ content: String) -> String {
        guard let tag = channelTag else { return content }
        return "[CH:\(tag)] \(content)"
    }

    /// Parse a [CH:xxx] prefix from message content.
    /// Returns (channel, strippedContent). If no tag found, returns (.site, original).
    static func parseChannelTag(from content: String) -> (channel: ChannelType, strippedContent: String) {
        guard content.hasPrefix("[CH:") else { return (.site, content) }
        guard let closeBracket = content.firstIndex(of: "]") else { return (.site, content) }
        let tag = String(content[content.index(content.startIndex, offsetBy: 4)..<closeBracket])
        let rest = String(content[content.index(after: closeBracket)...]).trimmingCharacters(in: .init(charactersIn: " "))
        if let channel = ChannelType.fromTag(tag) {
            return (channel, rest)
        }
        return (.site, content)
    }
}

struct ChannelSwitcherSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedChannel: ChannelType

    private let channels: [ChannelType] = [.site, .general, .defects, .deliveries]

    private var backgroundColor: Color {
        Color(red: 0.055, green: 0.063, blue: 0.071) // #0E1012
    }

    private var cardColor: Color {
        Color(red: 0.102, green: 0.110, blue: 0.125) // #1A1C20
    }

    private var borderColor: Color {
        Color(red: 0.165, green: 0.173, blue: 0.188) // #2A2C30
    }

    private var textColor: Color {
        Color.white
    }

    private var secondaryTextColor: Color {
        Color(red: 0.541, green: 0.557, blue: 0.588) // #8A8E96
    }

    private var accentColor: Color {
        Color(red: 0.910, green: 0.588, blue: 0.047) // #E8960C
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                List {
                    ForEach(channels) { channel in
                        Button(action: {
                            selectedChannel = channel
                            dismiss()
                        }) {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(channel.rawValue)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(textColor)
                                    Text(channel.subtitle)
                                        .font(.system(size: 12))
                                        .foregroundColor(secondaryTextColor)
                                        .lineLimit(1)
                                }

                                Spacer()

                                if selectedChannel == channel {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14))
                                        .foregroundColor(accentColor)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(cardColor)
                        .listRowSeparatorTint(borderColor)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .background(backgroundColor)
            .navigationTitle("Channels")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(accentColor)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
