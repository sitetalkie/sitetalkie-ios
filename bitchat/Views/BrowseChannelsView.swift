//
// BrowseChannelsView.swift
// bitchat
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import SwiftUI

struct BrowseChannelsView: View {
    @Environment(\.dismiss) private var dismiss

    private let backgroundColor = Color(red: 0.055, green: 0.063, blue: 0.071) // #0E1012
    private let textSecondary = Color(red: 0.541, green: 0.557, blue: 0.588)   // #8A8E96
    private let amber = Color(red: 0.910, green: 0.588, blue: 0.047)           // #E8960C

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(textSecondary)
                            .frame(width: 44, height: 44)
                    }
                    Spacer()
                    Text("Browse Channels")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, 8)

                Spacer()

                VStack(spacing: 12) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 36))
                        .foregroundColor(textSecondary.opacity(0.5))
                    Text("No other channels nearby")
                        .font(.system(size: 16))
                        .foregroundColor(textSecondary)
                }

                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }
}
