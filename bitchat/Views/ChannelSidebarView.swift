//
// ChannelSidebarView.swift
// bitchat
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import SwiftUI

struct ChannelSidebarView: View {
    @Binding var isPresented: Bool
    @Binding var selectedChannel: ChannelType
    @EnvironmentObject var viewModel: ChatViewModel
    @State private var showBrowseChannels = false

    // Same channel list as ChannelSwitcherSheet
    private let channels: [ChannelType] = [.site, .general, .defects, .deliveries]

    // Design system colors
    private let backgroundColor = Color(red: 0.055, green: 0.063, blue: 0.071) // #0E1012
    private let cardColor = Color(red: 0.102, green: 0.110, blue: 0.125)       // #1A1C20
    private let borderColor = Color(red: 0.165, green: 0.173, blue: 0.188)     // #2A2C30
    private let textPrimary = Color(red: 0.941, green: 0.941, blue: 0.941)     // #F0F0F0
    private let textSecondary = Color(red: 0.541, green: 0.557, blue: 0.588)   // #8A8E96
    private let textTertiary = Color(red: 0.353, green: 0.369, blue: 0.400)    // #5A5E66
    private let amber = Color(red: 0.910, green: 0.588, blue: 0.047)           // #E8960C
    private let successGreen = Color(red: 0.204, green: 0.780, blue: 0.349)    // #34C759

    private let sidebarWidth: CGFloat = 280

    var body: some View {
        ZStack(alignment: .leading) {
            // Semi-transparent overlay — fades in/out
            Color.black.opacity(isPresented ? 0.5 : 0)
                .ignoresSafeArea()
                .onTapGesture {
                    closeSidebar()
                }

            // Sidebar panel — slides via offset
            VStack(alignment: .leading, spacing: 0) {
                headerSection
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        channelsSection
                        actionButtons
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
                Spacer(minLength: 0)
                footerSection
            }
            .frame(width: sidebarWidth)
            .background(backgroundColor)
            .offset(x: isPresented ? 0 : -sidebarWidth)
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onEnded { value in
                        if value.translation.width < -50 {
                            closeSidebar()
                        }
                    }
            )
        }
        .allowsHitTesting(isPresented)
        .animation(.easeInOut(duration: 0.25), value: isPresented)
        .sheet(isPresented: $showBrowseChannels) {
            BrowseChannelsView()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Text("Channels")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            Spacer()
            Button(action: { closeSidebar() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(textSecondary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 16)
        .padding(.trailing, 4)
        .padding(.top, 8)
    }

    // MARK: - Channels Section

    private var channelsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Channels")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(textSecondary)
                .textCase(.uppercase)
                .tracking(0.5)

            ForEach(channels) { channel in
                let unread = viewModel.channelUnreadCounts[channel.rawValue] ?? 0
                channelRow(
                    name: channel.rawValue,
                    subtitle: channel.subtitle,
                    isSelected: selectedChannel == channel,
                    unreadCount: unread
                ) {
                    selectedChannel = channel
                    viewModel.markChannelAsRead(channel.rawValue)
                    closeSidebar()
                }
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 10) {
            Button(action: {
                showBrowseChannels = true
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(amber)
                        .frame(width: 24)

                    Text("Browse Channels")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(textPrimary)

                    Spacer()
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(cardColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(borderColor, lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack(spacing: 6) {
            Image(systemName: "lock.fill")
                .font(.system(size: 11))
                .foregroundColor(successGreen)
            Text("Channels are end-to-end encrypted")
                .font(.system(size: 12))
                .foregroundColor(textTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }

    // MARK: - Channel Row

    @ViewBuilder
    private func channelRow(
        name: String,
        subtitle: String,
        isSelected: Bool,
        unreadCount: Int,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Circle()
                    .fill(unreadCount > 0 ? amber : Color.clear)
                    .frame(width: 8, height: 8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? .white : textPrimary.opacity(0.8))
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(textTertiary)
                        .lineLimit(1)
                }

                Spacer()

                if unreadCount > 0 && !isSelected {
                    Text("\(unreadCount)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .frame(minWidth: 20, minHeight: 20)
                        .padding(.horizontal, 4)
                        .background(
                            Capsule()
                                .fill(amber)
                        )
                }

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(amber)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? cardColor : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func closeSidebar() {
        withAnimation(.easeInOut(duration: 0.25)) {
            isPresented = false
        }
    }
}
