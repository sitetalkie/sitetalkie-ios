import SwiftUI

struct BulletinBoardView: View {
    @ObservedObject private var store = BulletinStore.shared
    @State private var selectedFilter: BulletinFilter = .all
    @State private var selectedBulletin: Bulletin?

    enum BulletinFilter: String, CaseIterable {
        case all = "All"
        case unread = "Unread"
        case actionRequired = "Action Required"
    }

    // Design system
    private let backgroundColor = Color(red: 0.055, green: 0.063, blue: 0.071)
    private let cardColor = Color(red: 0.102, green: 0.110, blue: 0.125)
    private let textPrimary = Color(red: 0.941, green: 0.941, blue: 0.941)
    private let textSecondary = Color(red: 0.541, green: 0.557, blue: 0.588)
    private let textTertiary = Color(red: 0.353, green: 0.369, blue: 0.400)
    private let amber = Color(red: 0.910, green: 0.588, blue: 0.047)

    private var filteredBulletins: [Bulletin] {
        switch selectedFilter {
        case .all:
            return store.bulletins
        case .unread:
            return store.bulletins.filter { !$0.isRead }
        case .actionRequired:
            return store.bulletins.filter { $0.requiresAck && !$0.isAcknowledged }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Bulletin Board")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(textPrimary)

                if store.unreadCount > 0 {
                    Text("\(store.unreadCount)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .frame(minWidth: 20, minHeight: 20)
                        .background(Circle().fill(amber))
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            // Filter pills
            HStack(spacing: 8) {
                ForEach(BulletinFilter.allCases, id: \.rawValue) { filter in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedFilter = filter
                        }
                    }) {
                        Text(filter.rawValue)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(selectedFilter == filter ? .white : textSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(selectedFilter == filter ? amber : cardColor)
                            )
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)

            // Bulletin list
            if filteredBulletins.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(filteredBulletins) { bulletin in
                            BulletinCardView(bulletin: bulletin)
                                .onTapGesture {
                                    store.markAsRead(bulletin.id)
                                    selectedBulletin = bulletin
                                }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
        }
        .background(backgroundColor)
        .sheet(item: $selectedBulletin) { bulletin in
            BulletinDetailView(bulletin: bulletin)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "doc.text")
                .font(.system(size: 36))
                .foregroundColor(textTertiary)
            Text("No bulletins yet")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(textSecondary)
            Text("Site bulletins will appear here")
                .font(.system(size: 14))
                .foregroundColor(textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
