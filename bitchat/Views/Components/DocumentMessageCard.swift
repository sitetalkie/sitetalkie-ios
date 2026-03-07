//
// DocumentMessageCard.swift
// bitchat
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import SwiftUI

/// Displays a received document as a tappable card in the chat
struct DocumentMessageCard: View {
    let url: URL
    let onTap: () -> Void

    private var fileName: String {
        url.lastPathComponent
    }

    private var fileSizeString: String {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let bytes = attrs[.size] as? Int64 else {
            return ""
        }
        return DocumentMessageCard.formatFileSize(bytes)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "doc.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color(red: 0.910, green: 0.588, blue: 0.047)) // #E8960C

                VStack(alignment: .leading, spacing: 2) {
                    Text(fileName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color(red: 0.941, green: 0.941, blue: 0.941)) // #F0F0F0
                        .lineLimit(1)

                    if !fileSizeString.isEmpty {
                        Text(fileSizeString)
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 0.541, green: 0.557, blue: 0.588)) // #8A8E96
                    }
                }

                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(red: 0.102, green: 0.110, blue: 0.125)) // #1A1C20
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(red: 0.165, green: 0.173, blue: 0.188), lineWidth: 1) // #2A2C30
            )
        }
        .buttonStyle(.plain)
    }

    static func formatFileSize(_ bytes: Int64) -> String {
        if bytes >= 1_000_000 {
            let mb = Double(bytes) / 1_000_000.0
            return String(format: "%.1f MB", mb)
        } else if bytes >= 1_000 {
            let kb = Double(bytes) / 1_000.0
            return String(format: "%.0f KB", kb)
        } else {
            return "\(bytes) B"
        }
    }
}
