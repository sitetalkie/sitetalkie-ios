//
// SiteTabView.swift
// bitchat
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import SwiftUI
import CoreLocation

#if os(iOS)
struct SiteTabView: View {
    @EnvironmentObject var viewModel: ChatViewModel
    @EnvironmentObject var alertNavigationState: AlertNavigationState
    @ObservedObject private var locationManager = LocationChannelManager.shared
    @ObservedObject private var pinManager = SitePinManager.shared
    @ObservedObject private var distanceTracker = PinDistanceTracker.shared
    @ObservedObject private var geofenceManager = PinGeofenceManager.shared
    @ObservedObject private var bulletinStore = BulletinStore.shared
    @ObservedObject private var snagStore = SnagStore.shared

    @State private var selectedSegment = 0
    @State private var showCreatePin = false
    @State private var selectedPinForDetail: SitePin?
    @State private var showPinToast: String?

    // Design system colors
    private let backgroundColor = Color(red: 0.055, green: 0.063, blue: 0.071) // #0E1012
    private let cardColor = Color(red: 0.102, green: 0.110, blue: 0.125)       // #1A1C20
    private let borderColor = Color(red: 0.165, green: 0.173, blue: 0.188)     // #2A2C30
    private let textPrimary = Color(red: 0.941, green: 0.941, blue: 0.941)     // #F0F0F0
    private let textSecondary = Color(red: 0.541, green: 0.557, blue: 0.588)   // #8A8E96
    private let textTertiary = Color(red: 0.353, green: 0.369, blue: 0.400)    // #5A5E66
    private let amber = Color(red: 0.910, green: 0.588, blue: 0.047)           // #E8960C
    private let successGreen = Color(red: 0.204, green: 0.780, blue: 0.349)    // #34C759

    private let segments = ["Pins", "Snags", "Bulletin"]

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                // Header
                headerSection

                // Segment picker
                segmentPicker

                // Content based on selected segment
                switch selectedSegment {
                case 0:
                    pinsSection
                case 1:
                    SnagSectionView()
                        .environmentObject(viewModel)
                default:
                    bulletinSection
                }
            }
            .background(backgroundColor.ignoresSafeArea())
            .preferredColorScheme(.dark)
            .sheet(isPresented: $showCreatePin) {
                CreatePinView()
                    .environmentObject(viewModel)
            }
            .sheet(item: $selectedPinForDetail) { pin in
                PinDetailView(
                    pin: pin,
                    currentUserName: viewModel.nickname,
                    onDismiss: { selectedPinForDetail = nil },
                    onDelete: { p in viewModel.deleteAndBroadcastPin(p) }
                )
            }

            // Geofence banner overlay
            if let bannerPin = geofenceManager.activeBannerPin {
                VStack {
                    PinGeofenceBannerView(
                        pin: bannerPin,
                        onTap: {
                            geofenceManager.activeBannerPin = nil
                            selectedPinForDetail = bannerPin
                        },
                        onDismiss: {
                            withAnimation { geofenceManager.activeBannerPin = nil }
                        }
                    )
                    .padding(.top, 8)
                    Spacer()
                }
                .zIndex(200)
            }

            // Toast overlay
            if let toast = showPinToast {
                VStack {
                    Spacer()
                    Text(toast)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.8))
                        )
                        .padding(.bottom, 40)
                }
                .zIndex(201)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .sitePinReceived)) { notification in
            if let createdBy = notification.userInfo?["createdBy"] as? String {
                withAnimation {
                    showPinToast = "New pin from \(createdBy)"
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation { showPinToast = nil }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToBulletin)) { _ in
            withAnimation { selectedSegment = 2 }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Text("Site")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(backgroundColor)
    }

    // MARK: - Segment Picker

    private var segmentPicker: some View {
        HStack(spacing: 0) {
            ForEach(0..<segments.count, id: \.self) { index in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedSegment = index
                    }
                }) {
                    HStack(spacing: 4) {
                        Text(segments[index])
                            .font(.system(size: 14, weight: selectedSegment == index ? .semibold : .regular))
                            .foregroundColor(selectedSegment == index ? .white : textSecondary)

                        // Unread badge on Bulletin segment
                        if index == 2 && bulletinStore.unreadCount > 0 {
                            Text("\(bulletinStore.unreadCount)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .frame(minWidth: 16, minHeight: 16)
                                .background(Circle().fill(amber))
                        }

                        // Unviewed assigned snags badge
                        if index == 1 {
                            let userTrade = UserDefaults.standard.string(forKey: "com.sitetalkie.user.trade") ?? ""
                            let unviewedCount = snagStore.snags.filter { snag in
                                !userTrade.isEmpty
                                    && snag.trade == userTrade
                                    && snag.createdBy != viewModel.nickname
                                    && !snagStore.viewedSnagIds.contains(snag.id)
                            }.count
                            if unviewedCount > 0 {
                                Text("\(unviewedCount)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(minWidth: 16, minHeight: 16)
                                    .background(Circle().fill(amber))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        selectedSegment == index
                            ? amber.opacity(0.2)
                            : Color.clear
                    )
                    .overlay(
                        Rectangle()
                            .frame(height: 2)
                            .foregroundColor(selectedSegment == index ? amber : Color.clear),
                        alignment: .bottom
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .background(cardColor)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(borderColor),
            alignment: .bottom
        )
    }

    // MARK: - Pins Section

    private var pinsSection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Create Pin button
                Button(action: { showCreatePin = true }) {
                    HStack(spacing: 10) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(amber)
                        Text("Create Pin")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                            .foregroundColor(textTertiary)
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

                // Grouped pins by type (only active types)
                let activePins = pinManager.pins.filter { $0.type.isActive }
                let grouped = Dictionary(grouping: activePins, by: { $0.type })
                let pinOrder: [PinType] = [.hazard, .note]

                ForEach(pinOrder, id: \.self) { pinType in
                    if let typePins = grouped[pinType], !typePins.isEmpty {
                        let sorted = typePins.sorted { $0.createdAt > $1.createdAt }
                        pinGroupSection(type: pinType, pins: sorted)
                    }
                }

                if activePins.isEmpty {
                    emptyPinsView
                }
            }
            .padding(16)
        }
    }

    private func pinGroupSection(type: PinType, pins: [SitePin]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.system(size: 14))
                    .foregroundColor(type.color)
                Text(type.pluralName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(type.color)
                    .tracking(0.5)
                Text("\(pins.count)")
                    .font(.system(size: 12))
                    .foregroundColor(textTertiary)
            }

            ForEach(pins) { pin in
                pinRow(pin)
                    .onTapGesture {
                        selectedPinForDetail = pin
                    }
            }
        }
    }

    private func pinRow(_ pin: SitePin) -> some View {
        HStack(spacing: 0) {
            // 4pt coloured left border
            Rectangle()
                .fill(pin.isResolved ? Color.gray : pin.type.color)
                .frame(width: 4)

            HStack(spacing: 10) {
                Image(systemName: pin.type.icon)
                    .font(.system(size: 16))
                    .foregroundColor(pin.isResolved ? .gray : pin.type.color)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(pin.title)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(pin.isResolved ? .gray : textPrimary)
                            .lineLimit(1)

                        if pin.isResolved {
                            Text("Resolved \u{2713}")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(successGreen)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(successGreen.opacity(0.15))
                                )
                        }
                    }

                    HStack(spacing: 8) {
                        // Live distance
                        pinDistanceLabel(for: pin)

                        // Floor
                        if pin.floor != 0 {
                            Text(pin.floor < 0 ? "B\(abs(pin.floor))" : "Floor \(pin.floor)")
                                .font(.system(size: 12))
                                .foregroundColor(textSecondary)
                        }
                    }

                    HStack(spacing: 4) {
                        Text(pin.createdBy)
                            .font(.system(size: 12))
                            .foregroundColor(textTertiary)
                        Text("\u{00B7}")
                            .foregroundColor(textTertiary)
                        Text(pin.timeAgo)
                            .font(.system(size: 12))
                            .foregroundColor(textTertiary)
                    }
                }
                Spacer()
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 10)
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(cardColor)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if pin.createdBy == viewModel.nickname {
                Button(role: .destructive) {
                    pinManager.removePin(pin)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }

    private var emptyPinsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "mappin.slash")
                .font(.system(size: 36))
                .foregroundColor(textTertiary)
            Text("No pins yet")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(textSecondary)
            Text("Pins let you mark hazards and notes on your site.")
                .font(.system(size: 14))
                .foregroundColor(textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Distance Label

    @ViewBuilder
    private func pinDistanceLabel(for pin: SitePin) -> some View {
        let result = distanceTracker.formattedDistance(for: pin.id)
        let color: Color = result.color == .secondary ? textSecondary : textTertiary

        if distanceTracker.gpsState == .locating {
            Text(result.text)
                .font(.system(size: 12))
                .foregroundColor(color)
                .opacity(pulseOpacity)
                .onAppear { startPulse() }
        } else if distanceTracker.gpsState == .permissionDenied {
            Button(action: openAppSettings) {
                Text(result.text)
                    .font(.system(size: 12))
                    .foregroundColor(textTertiary)
                    .underline()
            }
            .buttonStyle(.plain)
        } else {
            Text(result.text)
                .font(.system(size: 12))
                .foregroundColor(color)
        }
    }

    @State private var pulseOpacity: Double = 1.0

    private func startPulse() {
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            pulseOpacity = 0.3
        }
    }

    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Bulletin Section

    private var bulletinSection: some View {
        BulletinBoardView()
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let sitePinReceived = Notification.Name("sitePinReceived")
    static let navigateToSiteTab = Notification.Name("navigateToSiteTab")
    static let navigateToBulletin = Notification.Name("navigateToBulletin")
}

#endif
