//
// QuickReplyView.swift
// bitchat
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import SwiftUI

struct QuickReplyView: View {
    @AppStorage("quickReplyExpanded") private var isExpanded: Bool = true
    let onReplyTap: (String) -> Void

    private let quickReplies = [
        "On my way",
        "Need you here",
        "Help needed",
        "All clear",
        "Send a photo",
        "Which floor?",
        "Check your DMs",
        "Understood 👍"
    ]

    private var backgroundColor: Color {
        Color(red: 0.102, green: 0.110, blue: 0.125) // #1A1C20
    }

    private var borderColor: Color {
        Color(red: 0.165, green: 0.173, blue: 0.188) // #2A2C30
    }

    private var textColor: Color {
        Color.white
    }

    var body: some View {
        VStack(spacing: 0) {
            if isExpanded {
                HStack(spacing: 8) {
                    // Collapse button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpanded = false
                        }
                    }) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 0.541, green: 0.557, blue: 0.588)) // #8A8E96
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(quickReplies, id: \.self) { reply in
                                Button(action: {
                                    onReplyTap(reply)
                                }) {
                                    Text(reply)
                                        .font(.system(size: 14))
                                        .foregroundColor(textColor)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(backgroundColor)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(borderColor, lineWidth: 1)
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 20))
                                }
                                .buttonStyle(.plain)
                            }

                            // Add invisible trailing spacer to ensure last item is fully visible
                            Color.clear
                                .frame(width: 1)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.top, 0)
                .padding(.bottom, 0)
            } else {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded = true
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 0.541, green: 0.557, blue: 0.588)) // #8A8E96
                        Text("Quick replies")
                            .font(.system(size: 13))
                            .foregroundColor(Color(red: 0.541, green: 0.557, blue: 0.588)) // #8A8E96
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
