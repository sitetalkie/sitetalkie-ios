//
// SnagSectionView.swift
// bitchat
//
// Dedicated snag list segment for the Site tab.
// Shows snag list with filters, create button, and detail navigation.
//

import SwiftUI

#if os(iOS)

struct SnagSectionView: View {
    @EnvironmentObject var viewModel: ChatViewModel
    @ObservedObject private var snagStore = SnagStore.shared

    @State private var selectedSubTab = 0 // 0 = My Snags, 1 = Assigned to Me
    @State private var showCreateSnag = false
    @State private var selectedSnag: Snag?

    // Filters
    @State private var filterStatuses: Set<SnagStatus> = [.open, .inProgress]
    @State private var filterPriorities: Set<SnagPriority> = Set(SnagPriority.allCases)
    @State private var filterTrade: String? = nil // nil = All Trades

    // Design system
    private let backgroundColor = Color(red: 0.055, green: 0.063, blue: 0.071) // #0E1012
    private let cardColor = Color(red: 0.102, green: 0.110, blue: 0.125)       // #1A1C20
    private let elevatedColor = Color(red: 0.141, green: 0.149, blue: 0.157)   // #242628
    private let borderColor = Color(red: 0.165, green: 0.173, blue: 0.188)     // #2A2C30
    private let textPrimary = Color(red: 0.941, green: 0.941, blue: 0.941)     // #F0F0F0
    private let textSecondary = Color(red: 0.541, green: 0.557, blue: 0.588)   // #8A8E96
    private let textTertiary = Color(red: 0.353, green: 0.369, blue: 0.400)    // #5A5E66
    private let amber = Color(red: 0.910, green: 0.588, blue: 0.047)           // #E8960C
    private let blue = Color(red: 0.231, green: 0.510, blue: 0.965)            // #3B82F6

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Sub-tabs
                subTabPicker

                // Create Snag button
                createSnagButton

                // Filter row
                filterRow

                // Snag list
                let filtered = filteredSnags
                if filtered.isEmpty {
                    emptyState
                } else {
                    ForEach(filtered) { snag in
                        snagCard(snag)
                            .onTapGesture {
                                selectedSnag = snag
                            }
                    }
                }
            }
            .padding(16)
        }
        .sheet(isPresented: $showCreateSnag) {
            CreateSnagView()
                .environmentObject(viewModel)
        }
        .sheet(item: $selectedSnag) { snag in
            SnagDetailView(snag: snag)
                .environmentObject(viewModel)
        }
    }

    // MARK: - Filtered Snags

    private var filteredSnags: [Snag] {
        snagStore.snags.filter { snag in
            // Sub-tab filter
            if selectedSubTab == 0 {
                // My Snags: created by current user
                if snag.createdBy != viewModel.nickname { return false }
            } else {
                // Assigned to Me: trade matches user's trade AND not created by current user
                let userTrade = UserDefaults.standard.string(forKey: "com.sitetalkie.user.trade") ?? ""
                if userTrade.isEmpty || snag.trade != userTrade || snag.createdBy == viewModel.nickname {
                    return false
                }
            }

            // Status filter
            if !filterStatuses.contains(snag.status) { return false }

            // Priority filter
            if !filterPriorities.contains(snag.priority) { return false }

            // Trade filter
            if let ft = filterTrade, snag.trade != ft { return false }

            return true
        }
        .sorted { $0.createdAt > $1.createdAt }
    }

    // MARK: - Sub-tab Picker

    private var subTabPicker: some View {
        HStack(spacing: 8) {
            subTabPill("My Snags", index: 0)
            subTabPill("Assigned to Me", index: 1)
            Spacer()
        }
    }

    private func subTabPill(_ title: String, index: Int) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedSubTab = index
            }
            if index == 1 {
                markAssignedSnagsViewed()
            }
        }) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(selectedSubTab == index ? .white : textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(selectedSubTab == index ? amber : cardColor)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Create Snag Button

    private var createSnagButton: some View {
        Button(action: { showCreateSnag = true }) {
            HStack(spacing: 10) {
                Image(systemName: "wrench.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                Text("Report Snag")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(amber)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Filter Row

    private var filterRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Status + Priority filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    // Status filters
                    ForEach(SnagStatus.allCases, id: \.self) { status in
                        filterPill(
                            title: status.displayName,
                            isSelected: filterStatuses.contains(status),
                            color: status.color,
                            action: { toggleStatusFilter(status) }
                        )
                    }

                    Rectangle()
                        .fill(borderColor)
                        .frame(width: 1, height: 20)

                    // Priority filters
                    ForEach(SnagPriority.allCases, id: \.self) { priority in
                        filterPill(
                            title: priority.label,
                            isSelected: filterPriorities.contains(priority),
                            color: priority.color,
                            action: { togglePriorityFilter(priority) }
                        )
                    }

                    // Trade filter
                    let activeTrades = Set(snagStore.snags.compactMap(\.trade)).sorted()
                    if !activeTrades.isEmpty {
                        Rectangle()
                            .fill(borderColor)
                            .frame(width: 1, height: 20)

                        Menu {
                            Button("All Trades") { filterTrade = nil }
                            ForEach(activeTrades, id: \.self) { trade in
                                Button(trade) { filterTrade = trade }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "wrench")
                                    .font(.system(size: 10))
                                Text(filterTrade ?? "All Trades")
                                    .font(.system(size: 12, weight: .medium))
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 9))
                            }
                            .foregroundColor(filterTrade != nil ? .white : textSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(filterTrade != nil ? amber.opacity(0.6) : cardColor)
                            )
                        }
                    }
                }
            }
        }
    }

    private func filterPill(title: String, isSelected: Bool, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isSelected ? .white : textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(isSelected ? color.opacity(0.6) : cardColor)
                )
        }
        .buttonStyle(.plain)
    }

    private func toggleStatusFilter(_ status: SnagStatus) {
        if filterStatuses.contains(status) {
            // Don't allow deselecting all
            if filterStatuses.count > 1 {
                filterStatuses.remove(status)
            }
        } else {
            filterStatuses.insert(status)
        }
    }

    private func togglePriorityFilter(_ priority: SnagPriority) {
        if filterPriorities.contains(priority) {
            if filterPriorities.count > 1 {
                filterPriorities.remove(priority)
            }
        } else {
            filterPriorities.insert(priority)
        }
    }

    private func markAssignedSnagsViewed() {
        let userTrade = UserDefaults.standard.string(forKey: "com.sitetalkie.user.trade") ?? ""
        guard !userTrade.isEmpty else { return }
        let ids = snagStore.snags.filter { snag in
            snag.trade == userTrade && snag.createdBy != viewModel.nickname
        }.map(\.id)
        snagStore.markSnagsViewed(ids)
    }

    // MARK: - Snag Card

    private func snagCard(_ snag: Snag) -> some View {
        HStack(spacing: 0) {
            // Left priority border
            Rectangle()
                .fill(snag.priority.color)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 6) {
                // Top row: status + priority pills
                HStack(spacing: 6) {
                    Spacer()

                    Text(snag.status.displayName)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(snag.status.color)
                        )

                    Text(snag.priority.label)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(snag.priority.color)
                        )
                }

                // Title
                Text(snag.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(textPrimary)
                    .lineLimit(1)

                // Description
                if let desc = snag.description, !desc.isEmpty {
                    Text(desc)
                        .font(.system(size: 12))
                        .foregroundColor(textSecondary)
                        .lineLimit(2)
                }

                // Metadata row
                HStack(spacing: 12) {
                    if let trade = snag.trade {
                        HStack(spacing: 3) {
                            Image(systemName: "wrench")
                                .font(.system(size: 10))
                            Text(trade)
                                .font(.system(size: 11))
                        }
                        .foregroundColor(textTertiary)
                    }

                    HStack(spacing: 3) {
                        Image(systemName: "building.2")
                            .font(.system(size: 10))
                        Text(snag.floorLabel)
                            .font(.system(size: 11))
                    }
                    .foregroundColor(textTertiary)

                    if snag.hasPhoto {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 10))
                            .foregroundColor(textTertiary)
                    }

                    Text(snag.timeAgo)
                        .font(.system(size: 11))
                        .foregroundColor(textTertiary)
                }
            }
            .padding(10)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(cardColor)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "wrench.and.screwdriver")
                .font(.system(size: 36))
                .foregroundColor(textTertiary)
            Text("No snags reported")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(textSecondary)
            Text("Report a snag to track defects on site.")
                .font(.system(size: 14))
                .foregroundColor(textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// Make Snag conform to Identifiable for .sheet(item:)
extension Snag: Hashable {
    static func == (lhs: Snag, rhs: Snag) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

#endif
