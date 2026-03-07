//
// PeopleListView.swift
// bitchat
//
// People tab — shows nearby BLE peers and recent DM contacts.
// This is free and unencumbered software released into the public domain.
//

import SwiftUI
import CoreLocation

#if os(iOS)
struct PeopleListView: View {
    @EnvironmentObject var viewModel: ChatViewModel
    @ObservedObject private var radarLocation = RadarLocationManager.shared
    @Binding var selectedTab: Int

    // MARK: - Colors (Design System)
    private let backgroundColor  = Color(red: 0.055, green: 0.063, blue: 0.071) // #0E1012
    private let cardBackground   = Color(red: 0.102, green: 0.110, blue: 0.125) // #1A1C20
    private let borderColor      = Color(red: 0.165, green: 0.173, blue: 0.188) // #2A2C30
    private let amber            = Color(red: 0.910, green: 0.588, blue: 0.047) // #E8960C
    private let textPrimary      = Color(red: 0.941, green: 0.941, blue: 0.941) // #F0F0F0
    private let textSecondary    = Color(red: 0.541, green: 0.557, blue: 0.588) // #8A8E96
    private let successGreen     = Color(red: 0.204, green: 0.780, blue: 0.349) // #34C759

    // MARK: - Computed Data

    /// Currently nearby BLE peers (excludes self), sorted by proximity.
    private var nearbyPeers: [BitchatPeer] {
        let now = Date()
        let timeout: TimeInterval = 120.0
        return viewModel.allPeers.filter { peer in
            guard peer.peerID != viewModel.meshService.myPeerID else { return false }
            guard !peer.displayName.hasPrefix("SiteNode") else { return false }
            let age = now.timeIntervalSince(peer.lastSeen)
            return age <= timeout
        }
        .sorted { p1, p2 in
            let d1 = RadarPeerPosition.distanceMetres(peer: p1, myLocation: radarLocation.location) ?? .greatestFiniteMagnitude
            let d2 = RadarPeerPosition.distanceMetres(peer: p2, myLocation: radarLocation.location) ?? .greatestFiniteMagnitude
            return d1 < d2
        }
    }

    /// Set of peer IDs that are currently nearby (for quick lookup).
    private var nearbyPeerIDs: Set<PeerID> {
        Set(nearbyPeers.map(\.peerID))
    }

    /// Recent DM contacts that are NOT currently nearby.
    /// Sorted by most recent message first.
    private var recentContacts: [(peer: BitchatPeer?, peerID: PeerID, name: String, lastMessageDate: Date?)] {
        let chats = viewModel.privateChats
        let myID = viewModel.meshService.myPeerID

        return chats.compactMap { (peerID, messages) -> (peer: BitchatPeer?, peerID: PeerID, name: String, lastMessageDate: Date?)? in
            // Skip self and peers that are currently nearby
            guard peerID != myID, !nearbyPeerIDs.contains(peerID) else { return nil }
            // Skip empty conversations
            guard !messages.isEmpty else { return nil }

            let peer = viewModel.allPeers.first(where: { $0.peerID == peerID })
            // Skip SiteNode relay infrastructure
            if let peer = peer, peer.displayName.hasPrefix("SiteNode") { return nil }
            let name: String
            if let peer = peer {
                name = peer.displayName
            } else {
                // Try to get name from messages
                let otherMessages = messages.filter { $0.senderPeerID != myID }
                name = otherMessages.first?.sender ?? String(peerID.id.prefix(8))
            }
            // Also filter by resolved name (covers case where peer object is nil)
            if name.hasPrefix("SiteNode") { return nil }
            let lastDate = messages.last?.timestamp
            return (peer: peer, peerID: peerID, name: name, lastMessageDate: lastDate)
        }
        .sorted { ($0.lastMessageDate ?? .distantPast) > ($1.lastMessageDate ?? .distantPast) }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    Text("People")
                        .font(.bitchatSystem(size: 24, weight: .bold))
                        .foregroundColor(textPrimary)
                        .padding(.top, 16)

                    // MARK: Nearby Now
                    nearbySectionView

                    // MARK: Recent
                    if !recentContacts.isEmpty {
                        recentSectionView
                    }

                    // MARK: Invite
                    sharePromptCard

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Nearby Section

    private var nearbySectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nearby Now")
                .font(.bitchatSystem(size: 12, weight: .medium))
                .foregroundColor(textSecondary)
                .textCase(.uppercase)

            if nearbyPeers.isEmpty {
                emptyNearbyView
            } else {
                ForEach(nearbyPeers, id: \.peerID) { peer in
                    nearbyPeerCard(peer)
                }
            }
        }
    }

    private var emptyNearbyView: some View {
        Button(action: { presentShareSheet() }) {
            VStack(spacing: 12) {
                Image(systemName: "antenna.radiowaves.left.and.right.slash")
                    .font(.system(size: 36))
                    .foregroundColor(textSecondary)
                Text("No one nearby")
                    .font(.bitchatSystem(size: 16, weight: .semibold))
                    .foregroundColor(textSecondary)
                Text("Share SiteTalkie with your site")
                    .font(.bitchatSystem(size: 14))
                    .foregroundColor(amber)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
        }
        .buttonStyle(.plain)
    }

    private func nearbyPeerCard(_ peer: BitchatPeer) -> some View {
        Button {
            openDM(with: peer.peerID)
        } label: {
            HStack(spacing: 12) {
                // Avatar
                peerAvatar(name: peer.displayName)

                // Name + trade
                VStack(alignment: .leading, spacing: 2) {
                    Text(peer.displayName)
                        .font(.bitchatSystem(size: 16, weight: .bold))
                        .foregroundColor(textPrimary)
                        .lineLimit(1)
                    if let trade = peer.trade, !trade.isEmpty {
                        Text(trade)
                            .font(.bitchatSystem(size: 14))
                            .foregroundColor(textSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Proximity zone badge
                if let zone = RadarPeerPosition.distanceLabelForPeopleList(
                    peer: peer, myLocation: radarLocation.location
                ) {
                    Text(zone)
                        .font(.system(size: 9, weight: .semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(zoneBadgeColor(zone).opacity(0.15))
                        .foregroundColor(zoneBadgeColor(zone))
                        .clipShape(Capsule())
                }

                // Message pill
                Text("Message")
                    .font(.bitchatSystem(size: 13, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(amber)
                    .clipShape(Capsule())
            }
            .padding(12)
            .background(cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Recent Section

    private var recentSectionView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent")
                .font(.bitchatSystem(size: 12, weight: .medium))
                .foregroundColor(textSecondary)
                .textCase(.uppercase)

            ForEach(recentContacts, id: \.peerID) { contact in
                recentContactCard(contact)
            }
        }
    }

    private func recentContactCard(_ contact: (peer: BitchatPeer?, peerID: PeerID, name: String, lastMessageDate: Date?)) -> some View {
        Button {
            openDM(with: contact.peerID)
        } label: {
            HStack(spacing: 12) {
                // Avatar
                peerAvatar(name: contact.name)

                // Name + last seen
                VStack(alignment: .leading, spacing: 2) {
                    Text(contact.name)
                        .font(.bitchatSystem(size: 16, weight: .bold))
                        .foregroundColor(textPrimary)
                        .lineLimit(1)
                    if let trade = contact.peer?.trade, !trade.isEmpty {
                        Text(trade)
                            .font(.bitchatSystem(size: 14))
                            .foregroundColor(textSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Status: nearby (green) or last seen
                statusLabel(for: contact)
            }
            .padding(12)
            .background(cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Share Prompt Card

    private var sharePromptCard: some View {
        Button(action: { presentShareSheet() }) {
            HStack(spacing: 14) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(amber)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Invite to SiteTalkie")
                        .font(.bitchatSystem(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    Text("More phones = stronger mesh")
                        .font(.bitchatSystem(size: 13))
                        .foregroundColor(textSecondary)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.bitchatSystem(size: 14, weight: .semibold))
                    .foregroundColor(amber)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(borderColor, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .frame(minHeight: 48)
    }

    // MARK: - Share Sheet

    private func presentShareSheet() {
        let shareText = "Download SiteTalkie — free offline messaging for construction sites. No signal needed. https://sitetalkie.com"
        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            var topVC = rootVC
            while let presented = topVC.presentedViewController {
                topVC = presented
            }
            activityVC.popoverPresentationController?.sourceView = topVC.view
            activityVC.popoverPresentationController?.sourceRect = CGRect(
                x: topVC.view.bounds.midX, y: topVC.view.bounds.maxY - 100,
                width: 0, height: 0
            )
            topVC.present(activityVC, animated: true)
        }
    }

    // MARK: - Helpers

    private func zoneBadgeColor(_ zone: String) -> Color {
        switch zone {
        case "Right here", "Close":
            return successGreen
        case "Nearby":
            return amber
        default:
            return textSecondary
        }
    }

    private func peerAvatar(name: String) -> some View {
        let initial = String(name.prefix(1)).uppercased()
        return ZStack {
            Circle()
                .fill(amber)
                .frame(width: 40, height: 40)
            Text(initial)
                .font(.bitchatSystem(size: 18, weight: .bold))
                .foregroundColor(.black)
        }
    }

    private func statusLabel(for contact: (peer: BitchatPeer?, peerID: PeerID, name: String, lastMessageDate: Date?)) -> some View {
        Group {
            if let peer = contact.peer, peer.isConnected || peer.isReachable {
                Text("Nearby")
                    .font(.bitchatSystem(size: 13, weight: .medium))
                    .foregroundColor(successGreen)
            } else if let date = contact.peer?.lastSeen {
                Text(relativeTime(from: date))
                    .font(.bitchatSystem(size: 13))
                    .foregroundColor(textSecondary)
            } else if let date = contact.lastMessageDate {
                Text(relativeTime(from: date))
                    .font(.bitchatSystem(size: 13))
                    .foregroundColor(textSecondary)
            }
        }
    }

    private func relativeTime(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let minutes = Int(interval / 60)
        let hours = Int(interval / 3600)
        let days = Int(interval / 86400)

        if minutes < 1 { return "just now" }
        if minutes < 60 { return "last seen \(minutes)m ago" }
        if hours < 24 { return "last seen \(hours)h ago" }
        if days < 7 { return "last seen \(days)d ago" }
        return "last seen \(days / 7)w ago"
    }

    private func openDM(with peerID: PeerID) {
        viewModel.startPrivateChat(with: peerID)
        // Switch to Chat tab so the DM sheet shows up
        selectedTab = 0
    }
}
#endif
