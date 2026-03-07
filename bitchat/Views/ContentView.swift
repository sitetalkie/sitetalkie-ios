//
// ContentView.swift
// bitchat
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import SwiftUI
#if os(iOS)
import UIKit
import AVFoundation
#endif
#if os(macOS)
import AppKit
#endif
import UniformTypeIdentifiers
import BitLogger

// MARK: - Supporting Types

//

//

private struct MessageDisplayItem: Identifiable {
    let id: String
    let message: BitchatMessage
}

// MARK: - Main Content View

struct ContentView: View {
    // MARK: - Properties
    
    @EnvironmentObject var viewModel: ChatViewModel
    @EnvironmentObject var alertNavigationState: AlertNavigationState
    @EnvironmentObject var siteDataStore: SiteDataStore
    @ObservedObject private var locationManager = LocationChannelManager.shared
    @ObservedObject private var bookmarks = GeohashBookmarksStore.shared
    @State private var messageText = ""
    @FocusState private var isTextFieldFocused: Bool
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var showSidebar = false
    @State private var showAppInfo = false
    @State private var showMessageActions = false
    @State private var selectedMessageSender: String?
    @State private var selectedMessageSenderID: PeerID?
    @FocusState private var isNicknameFieldFocused: Bool
    @State private var isAtBottomPublic: Bool = true
    @State private var isAtBottomPrivate: Bool = true
    @State private var lastScrollTime: Date = .distantPast
    @State private var scrollThrottleTimer: Timer?
    @State private var autocompleteDebounceTimer: Timer?
    @State private var showLocationChannelsSheet = false
    @State private var showVerifySheet = false
    @State private var expandedMessageIDs: Set<String> = []
    @State private var imagePreviewURL: URL? = nil
    @State private var recordingAlertMessage: String = ""
    @State private var showRecordingAlert = false
    @State private var isRecordingVoiceNote = false
    @State private var isPreparingVoiceNote = false
    @State private var recordingDuration: TimeInterval = 0
    @State private var recordingTimer: Timer?
    @State private var recordingStartDate: Date?
    @State private var pendingPhotoURL: URL? = nil
    @State private var pendingPhotoTargetPeer: PeerID? = nil
    @State private var pendingVoiceNoteURL: URL? = nil
    @State private var pendingDocumentURL: URL? = nil
    @State private var pendingDocumentName: String = ""
    @State private var pendingDocumentSize: Int64 = 0
    @State private var pendingDocumentTargetPeer: PeerID? = nil
    @State private var showDocumentPicker = false
    @State private var documentPreviewURL: URL? = nil
#if os(iOS)
    @State private var showImagePicker = false
    @State private var imagePickerSourceType: UIImagePickerController.SourceType = .camera
    @State private var showPhotoSourceSheet = false
    @State private var showCameraPermissionAlert = false
    @State private var imagePickerTargetPeer: PeerID? = nil // Captures DM context before picker shows
#else
    @State private var showMacImagePicker = false
    @State private var imagePickerTargetPeer: PeerID? = nil // Captures DM context before picker shows
#endif
    @ScaledMetric(relativeTo: .body) private var headerHeight: CGFloat = 44
    @ScaledMetric(relativeTo: .subheadline) private var headerPeerIconSize: CGFloat = 11
    @ScaledMetric(relativeTo: .subheadline) private var headerPeerCountFontSize: CGFloat = 12
    // Timer-based refresh removed; use LocationChannelManager live updates instead
    // Window sizes for rendering (infinite scroll up)
    @State private var windowCountPublic: Int = 300
    @State private var windowCountPrivate: [PeerID: Int] = [:]

    // Channel Switcher (persisted across restarts)
    @AppStorage("sitetalkie.selectedChannel") private var savedChannelRaw: String = "#site"
    @State private var selectedPrivateChannel: ChannelType = .site
    @State private var showChannelSidebar = false

    // Search
    @State private var isSearching = false
    @State private var searchText = ""
    @FocusState private var isSearchFieldFocused: Bool

    // Scroll to Bottom Pill
    @State private var showScrollToBottom = false
    @State private var lastMessageCount = 0
    @State private var scrollToBottomTrigger = false

    // Site Alert system
    @State private var activeSiteAlert: (type: SiteAlertType, floorLabel: String?, detail: String, sender: String)? = nil
    @State private var showAllClearOverlay = false
    @State private var lastAlertCheckCount = 0

    // Location Drop
    @State private var showLocationDropForm = false
    @State private var locationDropPulse = false

    // Attachment menu (+ button)
    @State private var showAttachmentMenu = false
    @State private var showCreatePinSheet = false

    // MARK: - Computed Properties
    
    // Construction design system colors
    private var backgroundColor: Color {
        Color(red: 0.055, green: 0.063, blue: 0.071) // #0E1012
    }

    private var textColor: Color {
        Color(red: 0.910, green: 0.588, blue: 0.047) // #E8960C amber
    }

    private var secondaryTextColor: Color {
        Color(red: 0.353, green: 0.369, blue: 0.400) // #5A5E66
    }

    private var selfBubbleColor: Color {
        Color(red: 0.910, green: 0.588, blue: 0.047) // #E8960C amber
    }

    private var otherBubbleColor: Color {
        Color(red: 0.141, green: 0.149, blue: 0.157) // #242628 dark card
    }

    private var selfBubbleTextColor: Color {
        Color(red: 0.102, green: 0.110, blue: 0.125) // #1A1C20
    }

    private var otherBubbleTextColor: Color {
        Color(red: 0.941, green: 0.941, blue: 0.941) // #F0F0F0
    }

    private var senderNameColor: Color {
        Color(red: 0.541, green: 0.557, blue: 0.588) // #8A8E96
    }

    private var headerBorderColor: Color {
        Color(red: 0.165, green: 0.173, blue: 0.188) // #2A2C30
    }

    private var inputBackgroundColor: Color {
        Color(red: 0.102, green: 0.110, blue: 0.125) // #1A1C20
    }

    private var headerLineLimit: Int? {
        dynamicTypeSize.isAccessibilitySize ? 2 : 1
    }

    private var peopleSheetTitle: String {
        String(localized: "content.header.people", comment: "Title for the people list sheet").lowercased()
    }

    private var peopleSheetSubtitle: String? {
        switch locationManager.selectedChannel {
        case .mesh:
            return "#mesh"
        case .location(let channel):
            return "#\(channel.geohash.lowercased())"
        }
    }

    private var peopleSheetActiveCount: Int {
        switch locationManager.selectedChannel {
        case .mesh:
            return viewModel.allPeers.filter { $0.peerID != viewModel.meshService.myPeerID }.count
        case .location:
            return viewModel.visibleGeohashPeople().count
        }
    }
    
    
    private struct PrivateHeaderContext {
        let headerPeerID: PeerID
        let peer: BitchatPeer?
        let displayName: String
        let isNostrAvailable: Bool
    }

// MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            mainHeaderView
                .onAppear {
                    viewModel.currentColorScheme = colorScheme
                    // Restore persisted channel selection
                    if let restored = ChannelType(rawValue: savedChannelRaw) {
                        selectedPrivateChannel = restored
                    }
                    viewModel.markChannelAsRead(selectedPrivateChannel.rawValue)
                    #if os(macOS)
                    // Focus message input on macOS launch, not nickname field
                    DispatchQueue.main.async {
                        isNicknameFieldFocused = false
                        isTextFieldFocused = true
                    }
                    #endif
                }
                .onChange(of: colorScheme) { newValue in
                    viewModel.currentColorScheme = newValue
                }

            // Search bar (shown when searching)
            if isSearching {
                SearchBarView(
                    searchText: $searchText,
                    isSearching: $isSearching,
                    isFocused: $isSearchFieldFocused
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Encryption badge — sits between header and messages, never overlaps
            HStack(spacing: 4) {
                Spacer()
                Image(systemName: "lock.fill")
                    .font(.system(size: 10))
                    .foregroundColor(Color(red: 0.204, green: 0.780, blue: 0.349)) // #34C759
                Text("End-to-end encrypted")
                    .font(.system(size: 11))
                    .foregroundColor(Color(red: 0.353, green: 0.369, blue: 0.400)) // #5A5E66
                Spacer()
            }
            .padding(.vertical, 6)
            .background(backgroundColor)

            // Message list or empty state - fills remaining space
            messagesView(privatePeer: nil, isAtBottom: $isAtBottomPublic)
                .background(backgroundColor)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Bottom controls - tight stack pinned to bottom
            if viewModel.selectedPrivateChatPeer == nil {
                inputView
            }
        }
        .background(backgroundColor)
        .foregroundColor(textColor)
        #if os(macOS)
        .frame(minWidth: 600, minHeight: 400)
        #endif
        .onChange(of: viewModel.selectedPrivateChatPeer) { newValue in
            if newValue != nil {
                showSidebar = true
            }
        }
        .sheet(
            isPresented: Binding(
                get: { showSidebar || viewModel.selectedPrivateChatPeer != nil },
                set: { isPresented in
                    // Don't dismiss the sheet if the image/document picker is showing
                    // This prevents the DM view from closing when selecting a photo or document
                    #if os(iOS)
                    let imagePickerActive = showImagePicker || showPhotoSourceSheet || showDocumentPicker
                    #else
                    let imagePickerActive = showMacImagePicker
                    #endif

                    if !isPresented && !imagePickerActive {
                        showSidebar = false
                        viewModel.endPrivateChat()
                    }
                }
            )
        ) {
            peopleSheetView
                #if os(iOS)
                .interactiveDismissDisabled(showImagePicker || showPhotoSourceSheet || showDocumentPicker)
                #else
                .interactiveDismissDisabled(showMacImagePicker)
                #endif
        }
        .sheet(isPresented: $showAppInfo) {
            AppInfoView()
                .environmentObject(viewModel)
                .onAppear { viewModel.isAppInfoPresented = true }
                .onDisappear { viewModel.isAppInfoPresented = false }
        }
        .sheet(isPresented: Binding(
            get: { viewModel.showingFingerprintFor != nil },
            set: { _ in viewModel.showingFingerprintFor = nil }
        )) {
            if let peerID = viewModel.showingFingerprintFor {
                FingerprintView(viewModel: viewModel, peerID: peerID)
                    .environmentObject(viewModel)
            }
        }
#if os(iOS)
        // Present image picker from root view for public channel only
        // DMs have their own fullScreenCover inside the sheet
        .fullScreenCover(isPresented: Binding(
            get: { showImagePicker && viewModel.selectedPrivateChatPeer == nil },
            set: { newValue in if !newValue { showImagePicker = false } }
        )) {
            ImagePickerView(sourceType: imagePickerSourceType) { image in
                let capturedTargetPeer = imagePickerTargetPeer
                showImagePicker = false
                imagePickerTargetPeer = nil
                if let image = image {
                    Task {
                        do {
                            let processedURL = try ImageUtils.processImage(image)
                            await MainActor.run {
                                // Store photo for preview instead of sending immediately
                                pendingPhotoURL = processedURL
                                pendingPhotoTargetPeer = capturedTargetPeer
                            }
                        } catch {
                            SecureLogger.error("Image processing failed: \(error)", category: .session)
                        }
                    }
                }
            }
            .environmentObject(viewModel)
            .ignoresSafeArea()
        }
        .overlay {
            if showPhotoSourceSheet && !showSidebar && viewModel.selectedPrivateChatPeer == nil {
                PhotoSourcePicker(
                    onTakePhoto: {
                        showPhotoSourceSheet = false
                        handleTakePhoto()
                    },
                    onChooseFromLibrary: {
                        showPhotoSourceSheet = false
                        handleChooseFromLibrary()
                    },
                    onCancel: {
                        showPhotoSourceSheet = false
                    }
                )
            }
        }
        .alert("Camera Access Required", isPresented: $showCameraPermissionAlert) {
            Button("Open Settings") {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("SiteTalkie needs camera access to take photos. Please enable it in Settings.")
        }
#endif
#if os(macOS)
        // Present Mac image picker from root view for all contexts (public and DM)
        .sheet(isPresented: $showMacImagePicker) {
            MacImagePickerView { url in
                let capturedTargetPeer = imagePickerTargetPeer
                showMacImagePicker = false
                imagePickerTargetPeer = nil
                if let url = url {
                    Task {
                        do {
                            let processedURL = try ImageUtils.processImage(at: url)
                            await MainActor.run {
                                // Store photo for preview instead of sending immediately
                                pendingPhotoURL = processedURL
                                pendingPhotoTargetPeer = capturedTargetPeer
                            }
                        } catch {
                            SecureLogger.error("Image processing failed: \(error)", category: .session)
                        }
                    }
                }
            }
            .environmentObject(viewModel)
        }
#endif
        .sheet(isPresented: Binding(
            get: { imagePreviewURL != nil },
            set: { presenting in if !presenting { imagePreviewURL = nil } }
        )) {
            if let url = imagePreviewURL {
                ImagePreviewView(url: url)
                    .environmentObject(viewModel)
            }
        }
        #if os(iOS)
        .sheet(isPresented: $showDocumentPicker) {
            DocumentPickerView { result in
                showDocumentPicker = false
                guard let doc = result else { return }
                pendingDocumentURL = doc.url
                pendingDocumentName = doc.name
                pendingDocumentSize = doc.size
                pendingDocumentTargetPeer = viewModel.selectedPrivateChatPeer
            }
        }
        .sheet(isPresented: $showLocationDropForm) {
            LocationDropFormView()
                .environmentObject(viewModel)
        }
        .sheet(isPresented: $showCreatePinSheet) {
            CreatePinView()
                .environmentObject(viewModel)
        }
        .sheet(isPresented: Binding(
            get: { documentPreviewURL != nil },
            set: { presenting in if !presenting { documentPreviewURL = nil } }
        )) {
            if let url = documentPreviewURL {
                DocumentPreviewView(url: url)
            }
        }
        #endif
        .alert("Recording Error", isPresented: $showRecordingAlert, actions: {
            Button("OK", role: .cancel) {}
        }, message: {
            Text(recordingAlertMessage)
        })
        .confirmationDialog(
            selectedMessageSender.map { "@\($0)" } ?? String(localized: "content.actions.title", comment: "Fallback title for the message action sheet"),
            isPresented: $showMessageActions,
            titleVisibility: .visible
        ) {
            Button("content.actions.mention") {
                if let sender = selectedMessageSender {
                    // Pre-fill the input with an @mention and focus the field
                    messageText = "@\(sender) "
                    isTextFieldFocused = true
                }
            }

            Button("content.actions.direct_message") {
                if let peerID = selectedMessageSenderID {
                    if peerID.isGeoChat {
                        if let full = viewModel.fullNostrHex(forSenderPeerID: peerID) {
                            viewModel.startGeohashDM(withPubkeyHex: full)
                        }
                    } else {
                        viewModel.startPrivateChat(with: peerID)
                    }
                    withAnimation(.easeInOut(duration: TransportConfig.uiAnimationMediumSeconds)) {
                        showSidebar = true
                    }
                }
            }

            Button("content.actions.hug") {
                if let sender = selectedMessageSender {
                    viewModel.sendMessage("/hug @\(sender)")
                }
            }

            Button("content.actions.slap") {
                if let sender = selectedMessageSender {
                    viewModel.sendMessage("/slap @\(sender)")
                }
            }

            Button("content.actions.block", role: .destructive) {
                // Prefer direct geohash block when we have a Nostr sender ID
                if let peerID = selectedMessageSenderID, peerID.isGeoChat,
                   let full = viewModel.fullNostrHex(forSenderPeerID: peerID),
                   let sender = selectedMessageSender {
                    viewModel.blockGeohashUser(pubkeyHexLowercased: full, displayName: sender)
                } else if let sender = selectedMessageSender {
                    viewModel.sendMessage("/block \(sender)")
                }
            }

            Button("common.cancel", role: .cancel) {}
        }
        .alert("content.alert.bluetooth_required.title", isPresented: $viewModel.showBluetoothAlert) {
            Button("content.alert.bluetooth_required.settings") {
                #if os(iOS)
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
                #endif
            }
            Button("common.ok", role: .cancel) {}
        } message: {
            Text(viewModel.bluetoothAlertMessage)
        }
        .onDisappear {
            // Clean up timers
            scrollThrottleTimer?.invalidate()
            autocompleteDebounceTimer?.invalidate()
        }
        .overlay {
            ChannelSidebarView(
                isPresented: $showChannelSidebar,
                selectedChannel: $selectedPrivateChannel
            )
            .environmentObject(viewModel)
            .zIndex(100)
        }
        .overlay(alignment: .leading) {
            // Invisible left-edge drag area for swipe-to-open
            if !showChannelSidebar {
                Color.clear
                    .frame(width: 30)
                    .frame(maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 20)
                            .onEnded { value in
                                if value.translation.width > 50 {
                                    withAnimation(.easeInOut(duration: 0.25)) {
                                        showChannelSidebar = true
                                    }
                                }
                            }
                    )
            }
        }
        // Full-screen site alert overlay (highest z-index)
        .overlay {
            if let alert = activeSiteAlert {
                SiteAlertOverlayView(
                    alertType: alert.type,
                    floorLabel: alert.floorLabel,
                    detail: alert.detail,
                    senderName: alert.sender,
                    onDismiss: {
                        withAnimation { activeSiteAlert = nil }
                    },
                    onOpenProtocol: alert.type.scenarioId.map { scenarioId in
                        {
                            withAnimation { activeSiteAlert = nil }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                alertNavigationState.openProtocol(scenarioId: scenarioId)
                            }
                        }
                    }
                )
                .zIndex(200)
            }
        }
        .overlay {
            if showAllClearOverlay {
                SiteAlertAllClearOverlayView {
                    withAnimation { showAllClearOverlay = false }
                }
                .zIndex(200)
            }
        }
        // Detect incoming site alerts from message changes
        .onChange(of: viewModel.messages.count) { newCount in
            guard newCount > lastAlertCheckCount else {
                lastAlertCheckCount = newCount
                return
            }
            lastAlertCheckCount = newCount

            // Check the most recent message
            guard let latest = viewModel.messages.last,
                  !viewModel.isSelfMessage(latest),
                  let parsed = SiteAlertType.parse(from: latest.content) else { return }

            let (baseName, _) = latest.sender.splitSuffix()

            if parsed.alertType == .allClear {
                // All Clear dismisses any active alert and shows brief green overlay
                withAnimation {
                    activeSiteAlert = nil
                    showAllClearOverlay = true
                }
            } else {
                withAnimation {
                    activeSiteAlert = (type: parsed.alertType, floorLabel: parsed.floorLabel, detail: parsed.detail, sender: baseName)
                }
            }

            // Schedule local notification if app is backgrounded
            SiteAlertNotificationHelper.scheduleLocalNotification(
                alertType: parsed.alertType,
                detail: parsed.detail
            )
        }
    }

    // MARK: - Message List View
    
    private func messagesView(privatePeer: PeerID?, isAtBottom: Binding<Bool>) -> some View {
        let messages: [BitchatMessage] = {
            if let peerID = privatePeer {
                return viewModel.getPrivateChatMessages(for: peerID)
            }
            return viewModel.messages
        }()

        let currentWindowCount: Int = {
            if let peer = privatePeer {
                return windowCountPrivate[peer] ?? TransportConfig.uiWindowInitialCountPrivate
            }
            return windowCountPublic
        }()

        let windowedMessages: [BitchatMessage] = Array(messages.suffix(currentWindowCount))

        // Filter messages by selected channel (public chat only)
        // - Regular messages: channel == nil → #site only; channel == "#general" → #general only
        // - System messages without a specific channel (channel == nil): show on ALL channels
        // - System messages with a specific channel: only show on that channel
        let channelFiltered: [BitchatMessage] = {
            guard privatePeer == nil else { return windowedMessages }
            if selectedPrivateChannel == .site {
                // #site: show messages with no channel tag, plus system messages without a specific channel
                return windowedMessages.filter { $0.channel == nil || ($0.sender == "system" && $0.channel == nil) }
            } else {
                let ch = selectedPrivateChannel.rawValue
                // Other channels: show matching channel messages, plus system messages without a specific channel
                return windowedMessages.filter { $0.channel == ch || ($0.sender == "system" && $0.channel == nil) }
            }
        }()

        // Filter messages based on search text (only for public chat)
        let filteredMessages: [BitchatMessage] = {
            if privatePeer == nil && isSearching && !searchText.isEmpty {
                return channelFiltered.filter { message in
                    message.content.localizedCaseInsensitiveContains(searchText) ||
                    message.sender.localizedCaseInsensitiveContains(searchText)
                }
            }
            return channelFiltered
        }()

        let contextKey: String = {
            if let peer = privatePeer { return "dm:\(peer)" }
            switch locationManager.selectedChannel {
            case .mesh: return "mesh"
            case .location(let ch): return "geo:\(ch.geohash)"
            }
        }()

        let messageItems: [MessageDisplayItem] = filteredMessages.compactMap { message in
            let trimmed = message.content.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return nil }
            return MessageDisplayItem(id: "\(contextKey)|\(message.id)", message: message)
        }

        let nearbyPeerCount = viewModel.allPeers.filter { $0.peerID != viewModel.meshService.myPeerID }.count
        let showEmptyState = privatePeer == nil && nearbyPeerCount == 0

        return Group {
        if showEmptyState {
            VStack(spacing: 0) {
                // Encryption badge
                HStack(spacing: 4) {
                    Spacer()
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color(red: 0.204, green: 0.780, blue: 0.349))
                    Text("End-to-end encrypted")
                        .font(.system(size: 12))
                        .foregroundColor(Color(red: 0.353, green: 0.369, blue: 0.400))
                    Spacer()
                }
                .padding(.vertical, 14)

                Spacer()

                VStack(spacing: 16) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 40))
                        .foregroundColor(Color(red: 0.910, green: 0.588, blue: 0.047))
                        .frame(maxWidth: .infinity, alignment: .center)

                    Text("No one nearby yet")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)

                    Text("SiteTalkie needs other phones nearby to work. Share it with your site.")
                        .font(.system(size: 14))
                        .foregroundColor(Color(red: 0.541, green: 0.557, blue: 0.588))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.horizontal, 32)

                    Button(action: { presentInviteSheet() }) {
                        Text("Invite your site")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(height: 48)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(red: 0.910, green: 0.588, blue: 0.047))
                            )
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, 32)
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 20)

                Spacer()
            }
            .background(backgroundColor)
        } else {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    // Search result count
                    if privatePeer == nil && isSearching && !searchText.isEmpty {
                        SearchResultCountView(count: messageItems.count)
                    }

                    // No results message when searching
                    if privatePeer == nil && isSearching && !searchText.isEmpty && messageItems.isEmpty {
                        VStack {
                            Spacer()
                            Text("No messages found")
                                .font(.system(size: 16))
                                .foregroundColor(Color(red: 0.541, green: 0.557, blue: 0.588)) // #8A8E96
                                .padding(.top, 60)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }

                    ForEach(Array(messageItems.enumerated()), id: \.element.id) { index, item in
                        let message = item.message
                        let previousMessage = index > 0 ? messageItems[index - 1].message : nil

                        // Show date separator when date changes
                        if let prevMsg = previousMessage,
                           !message.timestamp.isSameDay(as: prevMsg.timestamp) {
                            DateSeparatorView(date: message.timestamp)
                        }

                        messageRow(for: message)
                            .onAppear {
                                if message.id == windowedMessages.last?.id {
                                    isAtBottom.wrappedValue = true
                                }
                                if message.id == windowedMessages.first?.id,
                                   messages.count > windowedMessages.count {
                                    expandWindow(
                                        ifNeededFor: message,
                                        allMessages: messages,
                                        privatePeer: privatePeer,
                                        proxy: proxy
                                    )
                                }
                            }
                            .onDisappear {
                                if message.id == windowedMessages.last?.id {
                                    isAtBottom.wrappedValue = false
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if message.sender != "system" {
                                    messageText = "@\(message.sender) "
                                    isTextFieldFocused = true
                                }
                            }
                            .contextMenu {
                                Button("content.message.copy") {
                                    #if os(iOS)
                                    UIPasteboard.general.string = message.content
                                    #else
                                    let pb = NSPasteboard.general
                                    pb.clearContents()
                                    pb.setString(message.content, forType: .string)
                                    #endif
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                    }
                }
                .transaction { tx in if viewModel.isBatchingPublic { tx.disablesAnimations = true } }
                .padding(.vertical, 2)
            }
            .background(backgroundColor)
            .onOpenURL { handleOpenURL($0) }
            .onTapGesture(count: 3) {
                viewModel.sendMessage("/clear")
            }
            .onAppear {
                scrollToBottom(on: proxy, privatePeer: privatePeer, isAtBottom: isAtBottom)
            }
            .onChange(of: privatePeer) { _ in
                scrollToBottom(on: proxy, privatePeer: privatePeer, isAtBottom: isAtBottom)
            }
            .onChange(of: viewModel.messages.count) { newCount in
                if privatePeer == nil, let lastMsg = viewModel.messages.last {
                    let isFromSelf = (lastMsg.sender == viewModel.nickname) || lastMsg.sender.hasPrefix(viewModel.nickname + "#")
                    if !isFromSelf {
                        // Show scroll-to-bottom pill when new messages arrive and user is not at bottom
                        if !isAtBottom.wrappedValue && newCount > lastMessageCount {
                            showScrollToBottom = true
                        }
                        // Only autoscroll when user is at/near bottom
                        guard isAtBottom.wrappedValue else {
                            lastMessageCount = newCount
                            return
                        }
                    } else {
                        // Ensure we consider ourselves at bottom for subsequent messages
                        isAtBottom.wrappedValue = true
                    }
                    lastMessageCount = newCount
                    // Throttle scroll animations to prevent excessive UI updates
                    let now = Date()
                    if now.timeIntervalSince(lastScrollTime) > TransportConfig.uiScrollThrottleSeconds {
                        // Immediate scroll if enough time has passed
                        lastScrollTime = now
                        let contextKey: String = {
                            switch locationManager.selectedChannel {
                            case .mesh: return "mesh"
                            case .location(let ch): return "geo:\(ch.geohash)"
                            }
                        }()
                        let count = windowCountPublic
                        let target = viewModel.messages.suffix(count).last.map { "\(contextKey)|\($0.id)" }
                        DispatchQueue.main.async {
                            if let target = target { proxy.scrollTo(target, anchor: .bottom) }
                        }
                    } else {
                        // Schedule a delayed scroll
                        scrollThrottleTimer?.invalidate()
                        scrollThrottleTimer = Timer.scheduledTimer(withTimeInterval: TransportConfig.uiScrollThrottleSeconds, repeats: false) { [weak viewModel] _ in
                            Task { @MainActor in
                                lastScrollTime = Date()
                                let contextKey: String = {
                                    switch locationManager.selectedChannel {
                                    case .mesh: return "mesh"
                                    case .location(let ch): return "geo:\(ch.geohash)"
                                    }
                                }()
                                let count = windowCountPublic
                                let target = viewModel?.messages.suffix(count).last.map { "\(contextKey)|\($0.id)" }
                                if let target = target { proxy.scrollTo(target, anchor: .bottom) }
                            }
                        }
                    }
                }
            }
            .onChange(of: viewModel.privateChats) { _ in
                if let peerID = privatePeer,
                   let messages = viewModel.privateChats[peerID],
                   let lastMsg = messages.last {
                    let isFromSelf = (lastMsg.sender == viewModel.nickname) || lastMsg.sender.hasPrefix(viewModel.nickname + "#")
                    if !isFromSelf {
                        // Show scroll-to-bottom pill when new messages arrive and user is not at bottom
                        if !isAtBottom.wrappedValue {
                            showScrollToBottom = true
                        }
                        // Only autoscroll when user is at/near bottom
                        guard isAtBottom.wrappedValue else { return }
                    } else {
                        isAtBottom.wrappedValue = true
                    }
                    // Same throttling for private chats
                    let now = Date()
                    if now.timeIntervalSince(lastScrollTime) > TransportConfig.uiScrollThrottleSeconds {
                        lastScrollTime = now
                        let contextKey = "dm:\(peerID)"
                        let count = windowCountPrivate[peerID] ?? 300
                        let target = messages.suffix(count).last.map { "\(contextKey)|\($0.id)" }
                        DispatchQueue.main.async {
                            if let target = target { proxy.scrollTo(target, anchor: .bottom) }
                        }
                    } else {
                        scrollThrottleTimer?.invalidate()
                        scrollThrottleTimer = Timer.scheduledTimer(withTimeInterval: TransportConfig.uiScrollThrottleSeconds, repeats: false) { _ in
                            lastScrollTime = Date()
                            let contextKey = "dm:\(peerID)"
                            let count = windowCountPrivate[peerID] ?? 300
                            let target = messages.suffix(count).last.map { "\(contextKey)|\($0.id)" }
                            DispatchQueue.main.async {
                                if let target = target { proxy.scrollTo(target, anchor: .bottom) }
                            }
                        }
                    }
                }
            }
            .onChange(of: locationManager.selectedChannel) { newChannel in
                // When switching to a new geohash channel, scroll to the bottom
                guard privatePeer == nil else { return }
                switch newChannel {
                case .mesh:
                    break
                case .location(let ch):
                    // Reset window size
                    windowCountPublic = TransportConfig.uiWindowInitialCountPublic
                    let contextKey = "geo:\(ch.geohash)"
                    let last = viewModel.messages.suffix(windowCountPublic).last?.id
                    let target = last.map { "\(contextKey)|\($0)" }
                    isAtBottom.wrappedValue = true
                    DispatchQueue.main.async {
                        if let target = target { proxy.scrollTo(target, anchor: .bottom) }
                    }
                }
            }
            .onChange(of: scrollToBottomTrigger) { _ in
                if let peer = privatePeer {
                    let msgs = viewModel.getPrivateChatMessages(for: peer)
                    let count = windowCountPrivate[peer] ?? 300
                    if let target = msgs.suffix(count).last?.id {
                        let targetID = "dm:\(peer)|\(target)"
                        withAnimation {
                            proxy.scrollTo(targetID, anchor: .bottom)
                            isAtBottom.wrappedValue = true
                        }
                    }
                } else {
                    let contextKey: String = {
                        switch locationManager.selectedChannel {
                        case .mesh: return "mesh"
                        case .location(let ch): return "geo:\(ch.geohash)"
                        }
                    }()
                    let count = windowCountPublic
                    if let target = viewModel.messages.suffix(count).last?.id {
                        let targetID = "\(contextKey)|\(target)"
                        withAnimation {
                            proxy.scrollTo(targetID, anchor: .bottom)
                            isAtBottom.wrappedValue = true
                        }
                    }
                }
            }
            .onAppear {
                // Also check when view appears
                if let peerID = privatePeer {
                    // Try multiple times to ensure read receipts are sent
                    viewModel.markPrivateMessagesAsRead(from: peerID)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + TransportConfig.uiReadReceiptRetryShortSeconds) {
                        viewModel.markPrivateMessagesAsRead(from: peerID)
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + TransportConfig.uiReadReceiptRetryLongSeconds) {
                        viewModel.markPrivateMessagesAsRead(from: peerID)
                    }
                }
            }
        }
        .simultaneousGesture(
            TapGesture().onEnded {
                if showAttachmentMenu {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showAttachmentMenu = false
                    }
                }
            }
        )
        .overlay(alignment: .bottom) {
            // Scroll to bottom pill (public and DM)
            if showScrollToBottom && !isAtBottom.wrappedValue {
                ScrollToBottomPill {
                    withAnimation {
                        showScrollToBottom = false
                        scrollToBottomTrigger.toggle()
                    }
                }
                .padding(.bottom, 12)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onChange(of: isAtBottomPublic) { newValue in
            if newValue && privatePeer == nil {
                showScrollToBottom = false
            }
        }
        .onChange(of: isAtBottomPrivate) { newValue in
            if newValue && privatePeer != nil {
                showScrollToBottom = false
            }
        }
        .environment(\.openURL, OpenURLAction { url in
            // Intercept custom cashu: links created in attributed text
            if let scheme = url.scheme?.lowercased(), scheme == "cashu" || scheme == "lightning" {
                #if os(iOS)
                UIApplication.shared.open(url)
                return .handled
                #else
                // On non-iOS platforms, let the system handle or ignore
                return .systemAction
                #endif
            }
            return .systemAction
        })
        } // else
        } // Group
    }
    
    // MARK: - Input View

    @ViewBuilder
    private var inputView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Recording indicator (while recording)
            if isRecordingVoiceNote {
                recordingIndicator
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
            }

            // Photo preview (if pending)
            if let photoURL = pendingPhotoURL {
                photoPreview(photoURL: photoURL)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
            }

            // Voice note preview (if pending)
            if let voiceURL = pendingVoiceNoteURL {
                voiceNotePreview(voiceURL: voiceURL)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
            }

            // Document preview (if pending)
            if pendingDocumentURL != nil {
                documentPreview()
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
            }

            #if os(iOS)
            // Attachment menu row (slides up when + is tapped)
            if showAttachmentMenu {
                attachmentMenuRow
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            #endif

            // Text input row
            HStack(alignment: .center, spacing: 8) {
                #if os(iOS)
                attachmentPlusButton
                #endif

                TextField(
                    "",
                    text: $messageText,
                    prompt: Text("Message your site...")
                        .foregroundColor(secondaryTextColor)
                )
                .textFieldStyle(.plain)
                .font(.bitchatSystem(size: 16))
                .foregroundColor(.white)
                .focused($isTextFieldFocused)
                .autocorrectionDisabled(true)
#if os(iOS)
                .textInputAutocapitalization(.sentences)
#endif
                .submitLabel(.send)
                .onSubmit { sendMessage() }
                .padding(.vertical, 14)
                .padding(.horizontal, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(inputBackgroundColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(headerBorderColor, lineWidth: 1)
                )
                .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                .onChange(of: messageText) { newValue in
                    autocompleteDebounceTimer?.invalidate()
                    autocompleteDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: false) { [weak viewModel] _ in
                        let cursorPosition = newValue.count
                        Task { @MainActor in
                            viewModel?.updateAutocomplete(for: newValue, cursorPosition: cursorPosition)
                        }
                    }
                }

                #if os(iOS)
                sendOrMicButton
                #else
                HStack(alignment: .center, spacing: 6) {
                    if shouldShowMediaControls {
                        documentButton
                        attachmentButton
                    }

                    sendOrMicButton
                }
                #endif
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
    }
    
    private func handleOpenURL(_ url: URL) {
        guard url.scheme == "sitetalkie" else { return }
        switch url.host {
        case "user":
            let id = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            let peerID = PeerID(str: id.removingPercentEncoding ?? id)
            selectedMessageSenderID = peerID

            if peerID.isGeoDM || peerID.isGeoChat {
                selectedMessageSender = viewModel.geohashDisplayName(for: peerID)
            } else if let name = viewModel.meshService.peerNickname(peerID: peerID) {
                selectedMessageSender = name
            } else {
                selectedMessageSender = viewModel.messages.last(where: { $0.senderPeerID == peerID && $0.sender != "system" })?.sender
            }

            if viewModel.isSelfSender(peerID: peerID, displayName: selectedMessageSender) {
                selectedMessageSender = nil
                selectedMessageSenderID = nil
            } else {
                showMessageActions = true
            }

        case "geohash":
            let gh = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")).lowercased()
            let allowed = Set("0123456789bcdefghjkmnpqrstuvwxyz")
            guard (2...12).contains(gh.count), gh.allSatisfy({ allowed.contains($0) }) else { return }

            func levelForLength(_ len: Int) -> GeohashChannelLevel {
                switch len {
                case 0...2: return .region
                case 3...4: return .province
                case 5: return .city
                case 6: return .neighborhood
                case 7: return .block
                default: return .block
                }
            }

            let level = levelForLength(gh.count)
            let channel = GeohashChannel(level: level, geohash: gh)

            let inRegional = LocationChannelManager.shared.availableChannels.contains { $0.geohash == gh }
            if !inRegional && !LocationChannelManager.shared.availableChannels.isEmpty {
                LocationChannelManager.shared.markTeleported(for: gh, true)
            }
            LocationChannelManager.shared.select(ChannelID.location(channel))

        default:
            return
        }
    }

    private func scrollToBottom(on proxy: ScrollViewProxy,
                                privatePeer: PeerID?,
                                isAtBottom: Binding<Bool>) {
        let targetID: String? = {
            if let peer = privatePeer,
               let last = viewModel.getPrivateChatMessages(for: peer).suffix(300).last?.id {
                return "dm:\(peer)|\(last)"
            }
            let contextKey: String = {
                switch locationManager.selectedChannel {
                case .mesh: return "mesh"
                case .location(let ch): return "geo:\(ch.geohash)"
                }
            }()
            if let last = viewModel.messages.suffix(300).last?.id {
                return "\(contextKey)|\(last)"
            }
            return nil
        }()

        isAtBottom.wrappedValue = true

        DispatchQueue.main.async {
            if let targetID {
                proxy.scrollTo(targetID, anchor: .bottom)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            let secondTarget: String? = {
                if let peer = privatePeer,
                   let last = viewModel.getPrivateChatMessages(for: peer).suffix(300).last?.id {
                    return "dm:\(peer)|\(last)"
                }
                let contextKey: String = {
                    switch locationManager.selectedChannel {
                    case .mesh: return "mesh"
                    case .location(let ch): return "geo:\(ch.geohash)"
                    }
                }()
                if let last = viewModel.messages.suffix(300).last?.id {
                    return "\(contextKey)|\(last)"
                }
                return nil
            }()

            if let secondTarget {
                proxy.scrollTo(secondTarget, anchor: .bottom)
            }
        }
    }
    // MARK: - Actions
    
    private func sendMessage() {
        let trimmed = trimmedMessageText
        let hasPendingPhoto = pendingPhotoURL != nil
        let hasPendingVoiceNote = pendingVoiceNoteURL != nil
        let hasPendingDocument = pendingDocumentURL != nil

        // Must have either text or pending media
        guard !trimmed.isEmpty || hasPendingPhoto || hasPendingVoiceNote || hasPendingDocument else { return }

        // Clear input immediately for instant feedback
        messageText = ""

        // Send pending photo if present
        if let photoURL = pendingPhotoURL {
            let capturedTargetPeer = pendingPhotoTargetPeer
            pendingPhotoURL = nil
            pendingPhotoTargetPeer = nil

            // Send photo first
            viewModel.sendImage(from: photoURL, targetPeer: capturedTargetPeer)

            // Send caption immediately after (if present) - no async delay
            if !trimmed.isEmpty {
                viewModel.sendMessage(trimmed, channel: selectedPrivateChannel.rawValue)
            }
            return
        }

        // Send pending voice note if present
        if let voiceURL = pendingVoiceNoteURL {
            pendingVoiceNoteURL = nil

            // Send voice note first
            viewModel.sendVoiceNote(at: voiceURL)

            // Send caption immediately after (if present) - no async delay
            if !trimmed.isEmpty {
                viewModel.sendMessage(trimmed, channel: selectedPrivateChannel.rawValue)
            }
            return
        }

        // Send pending document if present
        if let docURL = pendingDocumentURL {
            // Don't send if file is over the limit
            guard pendingDocumentSize <= Int64(FileTransferLimits.maxPayloadBytes) else { return }

            let docName = pendingDocumentName
            let capturedTargetPeer = pendingDocumentTargetPeer
            pendingDocumentURL = nil
            pendingDocumentName = ""
            pendingDocumentSize = 0
            pendingDocumentTargetPeer = nil

            viewModel.sendDocument(from: docURL, fileName: docName, targetPeer: capturedTargetPeer)

            if !trimmed.isEmpty {
                viewModel.sendMessage(trimmed, channel: selectedPrivateChannel.rawValue)
            }
            return
        }

        // No pending media, just send text
        if !trimmed.isEmpty {
            let ch = selectedPrivateChannel.rawValue
            DispatchQueue.main.async {
                self.viewModel.sendMessage(trimmed, channel: ch)
            }
        }
    }
    
    private func presentInviteSheet() {
        #if os(iOS)
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
                x: topVC.view.bounds.midX, y: topVC.view.bounds.midY,
                width: 0, height: 0
            )
            topVC.present(activityVC, animated: true)
        }
        #endif
    }

    // MARK: - Sheet Content
    
    private var peopleSheetView: some View {
        Group {
            if viewModel.selectedPrivateChatPeer != nil {
                privateChatSheetView
            } else {
                peopleListSheetView
            }
        }
        .background(backgroundColor)
        .foregroundColor(textColor)
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 520)
        #endif
    }

    // MARK: - People Sheet Views
    
    private var peopleListSheetView: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Text(peopleSheetTitle)
                        .font(.bitchatSystem(size: 18, design: .monospaced))
                        .foregroundColor(textColor)
                    Spacer()
                    if case .mesh = locationManager.selectedChannel {
                        Button(action: { showVerifySheet = true }) {
                            Image(systemName: "qrcode")
                                .font(.bitchatSystem(size: 14))
                        }
                        .buttonStyle(.plain)
                        .help(
                            String(localized: "content.help.verification", comment: "Help text for verification button")
                        )
                    }
                    Button(action: {
                        withAnimation(.easeInOut(duration: TransportConfig.uiAnimationMediumSeconds)) {
                            dismiss()
                            showSidebar = false
                            showVerifySheet = false
                            viewModel.endPrivateChat()
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.bitchatSystem(size: 14, weight: .semibold, design: .monospaced))
                            .frame(width: 48, height: 48)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close")
                }
                let activeText = String.localizedStringWithFormat(
                    String(localized: "%@ active", comment: "Count of active users in the people sheet"),
                    "\(peopleSheetActiveCount)"
                )

                if let subtitle = peopleSheetSubtitle {
                    let subtitleColor: Color = {
                        switch locationManager.selectedChannel {
                        case .mesh:
                            return Color.blue
                        case .location:
                            return Color(red: 0.961, green: 0.620, blue: 0.043)
                        }
                    }()
                    HStack(spacing: 6) {
                        Text(subtitle)
                            .foregroundColor(subtitleColor)
                        Text(activeText)
                            .foregroundColor(.secondary)
                    }
                    .font(.bitchatSystem(size: 12, design: .monospaced))
                } else {
                    Text(activeText)
                        .font(.bitchatSystem(size: 12, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
            .background(backgroundColor)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    // Recent DM conversations
                    dmConversationsList

                    if case .location = locationManager.selectedChannel {
                        GeohashPeopleList(
                            viewModel: viewModel,
                            textColor: textColor,
                            secondaryTextColor: secondaryTextColor,
                            onTapPerson: {
                                showSidebar = true
                            }
                        )
                    } else {
                        MeshPeerList(
                            viewModel: viewModel,
                            textColor: textColor,
                            secondaryTextColor: secondaryTextColor,
                            onTapPeer: { peerID in
                                viewModel.startPrivateChat(with: peerID)
                                showSidebar = true
                            },
                            onToggleFavorite: { peerID in
                                viewModel.toggleFavorite(peerID: peerID)
                            },
                            onShowFingerprint: { peerID in
                                viewModel.showFingerprint(for: peerID)
                            }
                        )
                    }
                }
                .padding(.top, 4)
                .id(viewModel.allPeers.map { "\($0.peerID)-\($0.isConnected)" }.joined())
            }
        }
    }
    
    // MARK: - DM Conversations List

    @ViewBuilder
    private var dmConversationsList: some View {
        let dmPeers: [(peerID: PeerID, messages: [BitchatMessage])] = viewModel.privateChats
            .filter { !$0.value.isEmpty }
            .map { ($0.key, $0.value) }
            .sorted { a, b in
                (a.messages.last?.timestamp ?? .distantPast) > (b.messages.last?.timestamp ?? .distantPast)
            }

        if !dmPeers.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Messages")
                    .font(.bitchatSystem(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(secondaryTextColor)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                ForEach(dmPeers, id: \.peerID) { item in
                    dmConversationCard(peerID: item.peerID, messages: item.messages)
                }

                Divider()
                    .background(headerBorderColor)
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
            }
        }
    }

    private func dmConversationCard(peerID: PeerID, messages: [BitchatMessage]) -> some View {
        let headerPeerID = viewModel.getShortIDForNoiseKey(peerID)
        let peer = viewModel.getPeer(byID: headerPeerID)
        let displayName: String = peer?.displayName
            ?? viewModel.meshService.peerNickname(peerID: headerPeerID)
            ?? String(localized: "common.unknown", comment: "Fallback label for unknown peer")
        let lastMessage = messages.last
        let hasUnread = viewModel.hasUnreadMessages(for: peerID)

        let preview: String = {
            guard let msg = lastMessage else { return "" }
            if msg.content.hasPrefix("[voice] ") { return "Voice note" }
            if msg.content.hasPrefix("[image] ") { return "Photo" }
            return msg.content
        }()

        let timeText: String = {
            guard let msg = lastMessage else { return "" }
            return dmTimeAgo(from: msg.timestamp)
        }()

        return Button(action: {
            viewModel.startPrivateChat(with: peerID)
        }) {
            HStack(spacing: 12) {
                // Lock icon
                Image(systemName: "lock.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 0.204, green: 0.780, blue: 0.349)) // green lock
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(displayName)
                            .font(.bitchatSystem(size: 15, weight: .bold))
                            .foregroundColor(textColor)
                            .lineLimit(1)
                        Spacer()
                        Text(timeText)
                            .font(.bitchatSystem(size: 12))
                            .foregroundColor(secondaryTextColor)
                    }
                    HStack {
                        Text(preview)
                            .font(.bitchatSystem(size: 13))
                            .foregroundColor(secondaryTextColor)
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        if hasUnread {
                            Circle()
                                .fill(textColor)
                                .frame(width: 8, height: 8)
                        }
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(inputBackgroundColor) // #1A1C20
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(headerBorderColor, lineWidth: 1) // #2A2C30
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
    }

    private func dmTimeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 { return "now" }
        if interval < 3600 { return "\(Int(interval / 60))m" }
        if interval < 86400 { return "\(Int(interval / 3600))h" }
        return "\(Int(interval / 86400))d"
    }

    // MARK: - View Components

    private var privateChatSheetView: some View {
        VStack(spacing: 0) {
            if let privatePeerID = viewModel.selectedPrivateChatPeer {
                let headerContext = makePrivateHeaderContext(for: privatePeerID)

                HStack(spacing: 12) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: TransportConfig.uiAnimationMediumSeconds)) {
                            viewModel.endPrivateChat()
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.bitchatSystem(size: 12))
                            .foregroundColor(textColor)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(
                        String(localized: "content.accessibility.back_to_main_chat", comment: "Accessibility label for returning to main chat")
                    )

                    Spacer(minLength: 0)

                    HStack(spacing: 8) {
                        privateHeaderInfo(context: headerContext, privatePeerID: privatePeerID)
                        let isFavorite = viewModel.isFavorite(peerID: headerContext.headerPeerID)

                        if !privatePeerID.isGeoDM {
                            Button(action: {
                                viewModel.toggleFavorite(peerID: headerContext.headerPeerID)
                            }) {
                                Image(systemName: isFavorite ? "star.fill" : "star")
                                    .font(.bitchatSystem(size: 14))
                                    .foregroundColor(isFavorite ? Color.yellow : textColor)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(
                                isFavorite
                                ? String(localized: "content.accessibility.remove_favorite", comment: "Accessibility label to remove a favorite")
                                : String(localized: "content.accessibility.add_favorite", comment: "Accessibility label to add a favorite")
                            )
                        }
                    }
                    .frame(maxWidth: .infinity)

                    Spacer(minLength: 0)

                    Button(action: {
                        withAnimation(.easeInOut(duration: TransportConfig.uiAnimationMediumSeconds)) {
                            viewModel.endPrivateChat()
                            showSidebar = true
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.bitchatSystem(size: 12, weight: .semibold, design: .monospaced))
                            .frame(width: 32, height: 32)
                    }
                
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close")
                }
                .frame(height: headerHeight)
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 12)
                .background(backgroundColor)
            }

            messagesView(privatePeer: viewModel.selectedPrivateChatPeer, isAtBottom: $isAtBottomPrivate)
                .background(backgroundColor)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(alignment: .top) {
                    HStack(spacing: 4) {
                        Spacer()
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                            .foregroundColor(Color(red: 0.204, green: 0.780, blue: 0.349)) // #34C759
                        Text("End-to-end encrypted")
                            .font(.system(size: 11))
                            .foregroundColor(Color(red: 0.353, green: 0.369, blue: 0.400)) // #5A5E66
                        Spacer()
                    }
                    .padding(.vertical, 6)
                    .background(backgroundColor.opacity(0.95))
                }
            Divider()
            inputView
                .padding(.top, 8)
        }
        .background(backgroundColor)
        .foregroundColor(textColor)
        #if os(iOS)
        .confirmationDialog("Choose Photo Source", isPresented: $showPhotoSourceSheet, titleVisibility: .visible) {
            Button("Take Photo") { handleTakePhoto() }
            Button("Choose from Library") { handleChooseFromLibrary() }
            Button("Cancel", role: .cancel) { }
        }
        .fullScreenCover(isPresented: Binding(
            get: { showImagePicker && viewModel.selectedPrivateChatPeer != nil },
            set: { newValue in if !newValue { showImagePicker = false } }
        )) {
            ImagePickerView(sourceType: imagePickerSourceType) { image in
                let capturedTargetPeer = imagePickerTargetPeer
                showImagePicker = false
                imagePickerTargetPeer = nil
                if let image = image {
                    Task {
                        do {
                            let processedURL = try ImageUtils.processImage(image)
                            await MainActor.run {
                                pendingPhotoURL = processedURL
                                pendingPhotoTargetPeer = capturedTargetPeer
                            }
                        } catch {
                            SecureLogger.error("Image processing failed: \(error)", category: .session)
                        }
                    }
                }
            }
            .environmentObject(viewModel)
            .ignoresSafeArea()
        }
        #endif
        .simultaneousGesture(
            DragGesture(minimumDistance: 25, coordinateSpace: .local)
                .onEnded { value in
                    let horizontal = value.translation.width
                    let vertical = abs(value.translation.height)
                    guard horizontal > 80, vertical < 60 else { return }
                    withAnimation(.easeInOut(duration: TransportConfig.uiAnimationMediumSeconds)) {
                        showSidebar = true
                        viewModel.endPrivateChat()
                    }
                }
        )
    }

    private func privateHeaderInfo(context: PrivateHeaderContext, privatePeerID: PeerID) -> some View {
        Button(action: {
            viewModel.showFingerprint(for: context.headerPeerID)
        }) {
            HStack(spacing: 6) {
                if let connectionState = context.peer?.connectionState {
                    switch connectionState {
                    case .bluetoothConnected:
                        Image(systemName: "dot.radiowaves.left.and.right")
                            .font(.bitchatSystem(size: 14))
                            .foregroundColor(textColor)
                            .accessibilityLabel(String(localized: "content.accessibility.connected_mesh", comment: "Accessibility label for mesh-connected peer indicator"))
                    case .meshReachable:
                        Image(systemName: "point.3.filled.connected.trianglepath.dotted")
                            .font(.bitchatSystem(size: 14))
                            .foregroundColor(textColor)
                            .accessibilityLabel(String(localized: "content.accessibility.reachable_mesh", comment: "Accessibility label for mesh-reachable peer indicator"))
                    case .nostrAvailable:
                        Image(systemName: "globe")
                            .font(.bitchatSystem(size: 14))
                            .foregroundColor(.purple)
                            .accessibilityLabel(String(localized: "content.accessibility.available_nostr", comment: "Accessibility label for Nostr-available peer indicator"))
                    case .offline:
                        EmptyView()
                    }
                } else if viewModel.meshService.isPeerReachable(context.headerPeerID) {
                    Image(systemName: "point.3.filled.connected.trianglepath.dotted")
                        .font(.bitchatSystem(size: 14))
                        .foregroundColor(textColor)
                        .accessibilityLabel(String(localized: "content.accessibility.reachable_mesh", comment: "Accessibility label for mesh-reachable peer indicator"))
                } else if context.isNostrAvailable {
                    Image(systemName: "globe")
                        .font(.bitchatSystem(size: 14))
                        .foregroundColor(.purple)
                        .accessibilityLabel(String(localized: "content.accessibility.available_nostr", comment: "Accessibility label for Nostr-available peer indicator"))
                } else if viewModel.meshService.isPeerConnected(context.headerPeerID) || viewModel.connectedPeers.contains(context.headerPeerID) {
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .font(.bitchatSystem(size: 14))
                        .foregroundColor(textColor)
                        .accessibilityLabel(String(localized: "content.accessibility.connected_mesh", comment: "Accessibility label for mesh-connected peer indicator"))
                }

                Text(context.displayName)
                    .font(.bitchatSystem(size: 16, weight: .medium, design: .monospaced))
                    .foregroundColor(textColor)

                if !privatePeerID.isGeoDM {
                    let statusPeerID = viewModel.getShortIDForNoiseKey(privatePeerID)
                    let encryptionStatus = viewModel.getEncryptionStatus(for: statusPeerID)
                    if let icon = encryptionStatus.icon {
                        Image(systemName: icon)
                            .font(.bitchatSystem(size: 14))
                            .foregroundColor(encryptionStatus == .noiseVerified ? textColor :
                                             encryptionStatus == .noiseSecured ? textColor :
                                             Color.red)
                            .accessibilityLabel(
                                String(
                                    format: String(localized: "content.accessibility.encryption_status", comment: "Accessibility label announcing encryption status"),
                                    locale: .current,
                                    encryptionStatus.accessibilityDescription
                                )
                            )
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            String(
                format: String(localized: "content.accessibility.private_chat_header", comment: "Accessibility label describing the private chat header"),
                locale: .current,
                context.displayName
            )
        )
        .accessibilityHint(
            String(localized: "content.accessibility.view_fingerprint_hint", comment: "Accessibility hint for viewing encryption fingerprint")
        )
        .frame(height: headerHeight)
    }

    private func makePrivateHeaderContext(for privatePeerID: PeerID) -> PrivateHeaderContext {
        let headerPeerID = viewModel.getShortIDForNoiseKey(privatePeerID)
        let peer = viewModel.getPeer(byID: headerPeerID)

        let displayName: String = {
            if privatePeerID.isGeoDM, case .location(let ch) = locationManager.selectedChannel {
                let disp = viewModel.geohashDisplayName(for: privatePeerID)
                return "#\(ch.geohash)/@\(disp)"
            }
            if let name = peer?.displayName { return name }
            if let name = viewModel.meshService.peerNickname(peerID: headerPeerID) { return name }
            if let fav = FavoritesPersistenceService.shared.getFavoriteStatus(for: Data(hexString: headerPeerID.id) ?? Data()),
               !fav.peerNickname.isEmpty { return fav.peerNickname }
            if headerPeerID.id.count == 16 {
                let candidates = viewModel.identityManager.getCryptoIdentitiesByPeerIDPrefix(headerPeerID)
                if let id = candidates.first,
                   let social = viewModel.identityManager.getSocialIdentity(for: id.fingerprint) {
                    if let pet = social.localPetname, !pet.isEmpty { return pet }
                    if !social.claimedNickname.isEmpty { return social.claimedNickname }
                }
            } else if let keyData = headerPeerID.noiseKey {
                let fp = keyData.sha256Fingerprint()
                if let social = viewModel.identityManager.getSocialIdentity(for: fp) {
                    if let pet = social.localPetname, !pet.isEmpty { return pet }
                    if !social.claimedNickname.isEmpty { return social.claimedNickname }
                }
            }
            return String(localized: "common.unknown", comment: "Fallback label for unknown peer")
        }()

        let isNostrAvailable: Bool = {
            guard let connectionState = peer?.connectionState else {
                if let noiseKey = Data(hexString: headerPeerID.id),
                   let favoriteStatus = FavoritesPersistenceService.shared.getFavoriteStatus(for: noiseKey),
                   favoriteStatus.isMutual {
                    return true
                }
                return false
            }
            return connectionState == .nostrAvailable
        }()

        return PrivateHeaderContext(
            headerPeerID: headerPeerID,
            peer: peer,
            displayName: displayName,
            isNostrAvailable: isNostrAvailable
        )
    }

    // Compute channel-aware people count and color for toolbar (cross-platform)
    private func channelPeopleCountAndColor() -> (Int, Color) {
        switch locationManager.selectedChannel {
        case .location:
            let n = viewModel.geohashPeople.count
            return (n, n > 0 ? Color.green : secondaryTextColor)
        case .mesh:
            let counts = viewModel.allPeers.reduce(into: (others: 0, mesh: 0)) { counts, peer in
                guard peer.peerID != viewModel.meshService.myPeerID else { return }
                if peer.isConnected { counts.mesh += 1; counts.others += 1 }
                else if peer.isReachable { counts.others += 1 }
            }
            return (counts.others, counts.mesh > 0 ? Color.green : secondaryTextColor)
        }
    }

    
    private var mainHeaderView: some View {
        HStack(spacing: 0) {
            // Hamburger menu button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showChannelSidebar = true
                }
            }) {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)
            .frame(minWidth: 44, minHeight: 44)
            .accessibilityLabel("Open channels sidebar")

            // Channel name + subtitle
            VStack(alignment: .leading, spacing: 2) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showChannelSidebar = true
                    }
                }) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(selectedPrivateChannel.rawValue)
                            .font(.bitchatSystem(size: 18, weight: .bold))
                            .foregroundColor(Color(red: 0.910, green: 0.588, blue: 0.047)) // #E8960C
                            .lineLimit(headerLineLimit)
                            .fixedSize(horizontal: true, vertical: false)
                        Text(selectedPrivateChannel.subtitle)
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 0.541, green: 0.557, blue: 0.588)) // #8A8E96
                            .lineLimit(1)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    String(localized: "content.accessibility.location_channels", comment: "Accessibility label for the location channels button")
                )
            }
            .onTapGesture(count: 3) {
                viewModel.panicClearAllData()
            }

            Spacer()

            // Right side: action buttons
            HStack(spacing: 12) {
                // Unread indicator
                if viewModel.hasAnyUnreadMessages {
                    Button(action: { viewModel.openMostRelevantPrivateChat() }) {
                        Image(systemName: "envelope.fill")
                            .font(.bitchatSystem(size: 16))
                            .foregroundColor(textColor)
                    }
                    .buttonStyle(.plain)
                    .frame(minWidth: 48, minHeight: 48)
                    .accessibilityLabel(
                        String(localized: "content.accessibility.open_unread_private_chat", comment: "Accessibility label for the unread private chat button")
                    )
                }

                // Bookmark toggle (geochats)
                if case .location(let ch) = locationManager.selectedChannel {
                    Button(action: { bookmarks.toggle(ch.geohash) }) {
                        Image(systemName: bookmarks.isBookmarked(ch.geohash) ? "bookmark.fill" : "bookmark")
                            .font(.bitchatSystem(size: 16))
                            .foregroundColor(textColor)
                    }
                    .buttonStyle(.plain)
                    .frame(minWidth: 48, minHeight: 48)
                    .accessibilityLabel(
                        String(
                            format: String(localized: "content.accessibility.toggle_bookmark", comment: "Accessibility label for toggling a geohash bookmark"),
                            locale: .current,
                            ch.geohash
                        )
                    )
                }

                // Search button
                Button(action: {
                    withAnimation {
                        isSearching.toggle()
                        if isSearching {
                            isSearchFieldFocused = true
                        } else {
                            searchText = ""
                        }
                    }
                }) {
                    Image(systemName: isSearching ? "xmark" : "magnifyingglass")
                        .font(.bitchatSystem(size: 16))
                        .foregroundColor(textColor)
                }
                .buttonStyle(.plain)
                .frame(minWidth: 48, minHeight: 48)
                .accessibilityLabel(
                    String(localized: isSearching ? "Close search" : "Search messages", comment: "Accessibility label for search button")
                )

                // App info (macOS only — iOS uses Settings tab)
                #if os(macOS)
                Button(action: { showAppInfo = true }) {
                    Image(systemName: "gearshape")
                        .font(.bitchatSystem(size: 16))
                        .foregroundColor(secondaryTextColor)
                }
                .buttonStyle(.plain)
                .frame(minWidth: 48, minHeight: 48)
                #endif

            }
            .sheet(isPresented: $showVerifySheet) {
                VerificationSheetView(isPresented: $showVerifySheet)
                    .environmentObject(viewModel)
            }
        }
        .frame(height: headerHeight)
        .padding(.horizontal, 12)
        .background(backgroundColor)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(headerBorderColor),
            alignment: .bottom
        )
        .sheet(isPresented: $showLocationChannelsSheet) {
            LocationChannelsSheet(isPresented: $showLocationChannelsSheet)
                .environmentObject(viewModel)
                .onAppear { viewModel.isLocationChannelsSheetPresented = true }
                .onDisappear { viewModel.isLocationChannelsSheetPresented = false }
        }
        .onAppear {
            if case .mesh = locationManager.selectedChannel,
               locationManager.permissionState == .authorized,
               LocationChannelManager.shared.availableChannels.isEmpty {
                LocationChannelManager.shared.refreshChannels()
            }
        }
        .onChange(of: locationManager.selectedChannel) { _ in
            if case .mesh = locationManager.selectedChannel,
               locationManager.permissionState == .authorized,
               LocationChannelManager.shared.availableChannels.isEmpty {
                LocationChannelManager.shared.refreshChannels()
            }
        }
        .onChange(of: locationManager.permissionState) { _ in
            if case .mesh = locationManager.selectedChannel,
               locationManager.permissionState == .authorized,
               LocationChannelManager.shared.availableChannels.isEmpty {
                LocationChannelManager.shared.refreshChannels()
            }
        }
        .onChange(of: selectedPrivateChannel) { newChannel in
            savedChannelRaw = newChannel.rawValue
            viewModel.markChannelAsRead(newChannel.rawValue)
        }
        .alert("content.alert.screenshot.title", isPresented: $viewModel.showScreenshotPrivacyWarning) {
            Button("common.ok", role: .cancel) {}
        } message: {
            Text("content.alert.screenshot.message")
        }
        .background(backgroundColor.opacity(0.95))
    }

}

// MARK: - Helper Views

// Rounded payment chip button
//

private enum MessageMedia {
    case voice(URL)
    case image(URL)
    case document(URL)

    var url: URL {
        switch self {
        case .voice(let url), .image(let url), .document(let url):
            return url
        }
    }
}

private extension ContentView {
    func mediaAttachment(for message: BitchatMessage) -> MessageMedia? {
        guard let baseDirectory = applicationFilesDirectory() else { return nil }

        // Extract filename from message content
        func url(from prefix: String, subdirectory: String) -> URL? {
            guard message.content.hasPrefix(prefix) else { return nil }
            let filename = String(message.content.dropFirst(prefix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !filename.isEmpty else { return nil }

            // Construct URL directly without fileExists check (avoids blocking disk I/O in view body)
            // Files are checked during playback/display, so missing files fail gracefully
            let directory = baseDirectory.appendingPathComponent(subdirectory, isDirectory: true)
            return directory.appendingPathComponent(filename)
        }

        // Try outgoing first (most common for sent media), fall back to incoming
        if message.content.hasPrefix("[voice] ") {
            let filename = String(message.content.dropFirst("[voice] ".count)).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !filename.isEmpty else { return nil }
            // Check outgoing first for sent messages, incoming for received
            let subdir = message.sender == viewModel.nickname ? "voicenotes/outgoing" : "voicenotes/incoming"
            let url = baseDirectory.appendingPathComponent(subdir, isDirectory: true).appendingPathComponent(filename)
            return .voice(url)
        }
        if message.content.hasPrefix("[image] ") {
            let filename = String(message.content.dropFirst("[image] ".count)).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !filename.isEmpty else { return nil }
            let subdir = message.sender == viewModel.nickname ? "images/outgoing" : "images/incoming"
            let url = baseDirectory.appendingPathComponent(subdir, isDirectory: true).appendingPathComponent(filename)
            return .image(url)
        }
        if message.content.hasPrefix("[file] ") {
            let filename = String(message.content.dropFirst("[file] ".count)).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !filename.isEmpty else { return nil }
            let subdir = message.sender == viewModel.nickname ? "files/outgoing" : "files/incoming"
            let url = baseDirectory.appendingPathComponent(subdir, isDirectory: true).appendingPathComponent(filename)
            return .document(url)
        }
        return nil
    }

    func mediaSendState(for message: BitchatMessage, mediaURL: URL) -> (isSending: Bool, progress: Double?, canCancel: Bool) {
        var isSending = false
        var progress: Double?
        if let status = message.deliveryStatus {
            switch status {
            case .sending:
                isSending = true
                progress = 0
            case .partiallyDelivered(let reached, let total):
                if total > 0 {
                    isSending = true
                    progress = Double(reached) / Double(total)
                }
            case .sent, .read, .delivered, .failed:
                break
            }
        }
        let isOutgoing = mediaURL.path.contains("/outgoing/")
        let canCancel = isSending && isOutgoing
        let clamped = progress.map { max(0, min(1, $0)) }
        return (isSending, isSending ? clamped : nil, canCancel)
    }

    @ViewBuilder
    private func messageRow(for message: BitchatMessage) -> some View {
        if message.sender == "system" && message.content.hasPrefix("[BULLETIN_NOTICE:") {
            bulletinNoticeRow(message)
        } else if message.sender == "system" && message.content.hasPrefix("[PIN_NOTICE:") {
            pinNoticeRow(message)
        } else if message.sender == "system" && message.content.hasPrefix("[PIN_RESOLVED:") {
            pinResolvedRow(message)
        } else if message.sender == "system" && message.content.hasPrefix("[PIN_DELETED:") {
            pinDeletedRow(message)
        } else if message.sender == "system" && message.content.hasPrefix("[PIN_EXPIRED:") {
            pinExpiredRow(message)
        } else if message.content.hasPrefix("[LOCATION_DROP:") {
            if let drop = LocationDropCardView.decode(from: message.content) {
                LocationDropCardView(
                    drop: drop,
                    isSelf: viewModel.isSelfMessage(message),
                    timestamp: message.relativeTimestamp
                )
            }
        } else if message.content.hasPrefix("[SITE_PIN:") || message.content.hasPrefix("[SITE_PIN_RESOLVED:") || message.content.hasPrefix("[SITE_PIN_DELETED:") || message.content.hasPrefix("[SNAG_PROGRESS:") {
            // Raw pin/snag protocol messages should never appear as chat bubbles
            EmptyView()
        } else if message.sender == "system" {
            systemMessageRow(message)
        } else if let parsed = SiteAlertType.parse(from: message.content) {
            let (baseName, _) = message.sender.splitSuffix()
            SiteAlertBannerView(
                alertType: parsed.alertType,
                floorLabel: parsed.floorLabel,
                detail: parsed.detail,
                senderName: baseName,
                timestamp: message.relativeTimestamp,
                scenarioTitle: parsed.alertType.scenarioId.flatMap { id in
                    ScenarioData.all(siteAddress: siteDataStore.siteConfig?.siteAddress ?? "")
                        .first(where: { $0.id == id })?.title
                },
                onOpenProtocol: parsed.alertType.scenarioId.map { scenarioId in
                    { alertNavigationState.openProtocol(scenarioId: scenarioId) }
                }
            )
        } else if let snag = SnagMessage.parse(from: message.content) {
            let (baseName, _) = message.sender.splitSuffix()
            SnagCardView(
                snag: snag,
                senderName: baseName,
                timestamp: message.relativeTimestamp
            )
        } else if let media = mediaAttachment(for: message) {
            bubbleWrappedView(for: message) {
                mediaContentView(message: message, media: media)
            }
        } else {
            bubbleWrappedView(for: message) {
                TextMessageView(message: message, expandedMessageIDs: $expandedMessageIDs, bubbleMode: true)
            }
        }
    }

    /// Wraps content in a construction-style message bubble with sender name and timestamp
    @ViewBuilder
    private func bubbleWrappedView<Content: View>(for message: BitchatMessage, @ViewBuilder content: () -> Content) -> some View {
        let isSelf = viewModel.isSelfMessage(message)
        let bubbleBg = isSelf ? selfBubbleColor : otherBubbleColor

        VStack(alignment: isSelf ? .trailing : .leading, spacing: 3) {
            // Sender name + trade badge above bubble
            if !isSelf {
                let (baseName, _) = message.sender.splitSuffix()
                let trade = getTrade(for: message)

                if let trade = trade, !trade.isEmpty {
                    (Text(baseName)
                        .font(.bitchatSystem(size: 13, weight: .bold)) +
                     Text(" · \(trade)")
                        .font(.bitchatSystem(size: 12)))
                        .foregroundColor(senderNameColor)
                        .padding(.leading, 4)
                } else {
                    Text(baseName)
                        .font(.bitchatSystem(size: 13, weight: .bold))
                        .foregroundColor(senderNameColor)
                        .padding(.leading, 4)
                }
            } else {
                let trade = getTrade(for: message)
                if let trade = trade, !trade.isEmpty {
                    let (baseName, _) = message.sender.splitSuffix()
                    (Text(baseName)
                        .font(.bitchatSystem(size: 13, weight: .bold)) +
                     Text(" · \(trade)")
                        .font(.bitchatSystem(size: 12)))
                        .foregroundColor(senderNameColor)
                        .padding(.trailing, 4)
                }
            }

            // Bubble
            content()
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(bubbleBg)
                )
                .frame(maxWidth: 300, alignment: isSelf ? .trailing : .leading)

            // Auto-translate for incoming messages
            if !isSelf {
                ChatMessageTranslation(text: message.content)
            }

            // Timestamp and delivery status below bubble
            HStack(spacing: 4) {
                Text(message.relativeTimestamp)
                    .font(.bitchatSystem(size: 11))
                    .foregroundColor(secondaryTextColor)

                if isSelf, let status = message.deliveryStatus {
                    DeliveryStatusView(status: status)
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(maxWidth: .infinity, alignment: isSelf ? .trailing : .leading)
    }

    private func getTrade(for message: BitchatMessage) -> String? {
        // For self messages, read trade from UserDefaults
        if viewModel.isSelfMessage(message) {
            let trade = UserDefaults.standard.string(forKey: "com.sitetalkie.user.trade") ?? ""
            return trade.isEmpty ? nil : trade
        }
        // For other users, get trade from peer metadata
        if let peerID = message.senderPeerID {
            if let peer = viewModel.getPeer(byID: peerID) {
                return peer.trade
            }
        }
        return nil
    }

    /// Media content for inside a bubble (without the old header wrapping)
    @ViewBuilder
    private func mediaContentView(message: BitchatMessage, media: MessageMedia) -> some View {
        let mediaURL = media.url
        let state = mediaSendState(for: message, mediaURL: mediaURL)
        let isOutgoing = mediaURL.path.contains("/outgoing/")
        let isAuthoredByUs = isOutgoing || (message.senderPeerID == viewModel.meshService.myPeerID)
        let shouldBlurImage = !isAuthoredByUs
        let cancelAction: (() -> Void)? = state.canCancel ? { viewModel.cancelMediaSend(messageID: message.id) } : nil

        VStack(alignment: .leading, spacing: 4) {
            // Delivery status for private messages
            if message.isPrivate && message.sender == viewModel.nickname,
               let status = message.deliveryStatus {
                HStack {
                    Spacer()
                    DeliveryStatusView(status: status)
                }
            }

            switch media {
            case .voice(let url):
                VoiceNoteView(
                    url: url,
                    isSending: state.isSending,
                    sendProgress: state.progress,
                    onCancel: cancelAction
                )
            case .image(let url):
                BlockRevealImageView(
                    url: url,
                    revealProgress: state.progress,
                    isSending: state.isSending,
                    onCancel: cancelAction,
                    initiallyBlurred: shouldBlurImage,
                    onOpen: {
                        if !state.isSending {
                            imagePreviewURL = url
                        }
                    },
                    onDelete: shouldBlurImage ? {
                        viewModel.deleteMediaMessage(messageID: message.id)
                    } : nil
                )
                .frame(maxWidth: 280)
            case .document(let url):
                DocumentMessageCard(url: url) {
                    documentPreviewURL = url
                }
                .frame(maxWidth: 280)
            }
        }
    }

    @ViewBuilder
    private func systemMessageRow(_ message: BitchatMessage) -> some View {
        VStack(spacing: 2) {
            Text(message.content)
                .font(.bitchatSystem(size: 14))
                .foregroundColor(secondaryTextColor)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
            Text(message.formattedTimestamp)
                .font(.bitchatSystem(size: 12))
                .foregroundColor(secondaryTextColor.opacity(0.6))
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Pin System Message Cards

    /// Themed slim card for pin system messages with left colour border
    @ViewBuilder
    private func pinSystemCard(
        icon: String,
        accentColor: Color,
        text: String,
        subtitle: String?,
        timestamp: String
    ) -> some View {
        HStack(spacing: 0) {
            // Left coloured border
            RoundedRectangle(cornerRadius: 1.5)
                .fill(accentColor)
                .frame(width: 3)

            HStack(spacing: 10) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(accentColor)

                // Text content
                VStack(alignment: .leading, spacing: 2) {
                    Text(text)
                        .font(.system(size: 13))
                        .foregroundColor(Color(red: 0.941, green: 0.941, blue: 0.941)) // #F0F0F0
                        .lineLimit(2)

                    if let subtitle = subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 11))
                            .foregroundColor(Color(red: 0.541, green: 0.557, blue: 0.588)) // #8A8E96
                    }
                }

                Spacer(minLength: 4)

                // Timestamp
                Text(timestamp)
                    .font(.system(size: 11))
                    .foregroundColor(Color(red: 0.353, green: 0.369, blue: 0.400)) // #5A5E66
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(accentColor.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
    }

    /// Format a channels CSV as "on #defects, #site"
    private func channelsSubtitle(from channelsCSV: String) -> String? {
        if channelsCSV.isEmpty || channelsCSV == "all" { return nil }
        let tags = channelsCSV.components(separatedBy: ",").map { "#\($0.trimmingCharacters(in: .whitespaces))" }
        return "on \(tags.joined(separator: ", "))"
    }

    /// Bulletin received — amber themed slim card
    @ViewBuilder
    private func bulletinNoticeRow(_ message: BitchatMessage) -> some View {
        // Parse [BULLETIN_NOTICE:{id}:{title}]
        let inside = message.content
            .replacingOccurrences(of: "[BULLETIN_NOTICE:", with: "")
            .replacingOccurrences(of: "]", with: "")
        let parts = inside.components(separatedBy: ":")
        let title = parts.count > 1 ? parts.dropFirst().joined(separator: ":") : "New Bulletin"
        let amberColor = Color(red: 0.910, green: 0.588, blue: 0.047)

        pinSystemCard(
            icon: "doc.text.fill",
            accentColor: amberColor,
            text: "New Bulletin: \(title)",
            subtitle: "Tap to view",
            timestamp: message.relativeTimestamp
        )
        .contentShape(Rectangle())
        .onTapGesture {
            NotificationCenter.default.post(name: .navigateToBulletin, object: nil)
        }
    }

    /// Pin created — themed slim card
    @ViewBuilder
    private func pinNoticeRow(_ message: BitchatMessage) -> some View {
        // Parse [PIN_NOTICE:createdBy:pinTypeRaw:title:channelsCSV]
        let parts = message.content
            .replacingOccurrences(of: "[PIN_NOTICE:", with: "")
            .replacingOccurrences(of: "]", with: "")
            .components(separatedBy: ":")
        let createdBy = parts.first ?? "Someone"
        let typeRaw = parts.count > 1 ? parts[1] : "note"
        let pinType = PinType(rawValue: typeRaw) ?? .note
        let title = parts.count > 2 ? parts[2] : ""
        let channelsCSV = parts.count > 3 ? parts[3] : ""

        let text = title.isEmpty
            ? "\(createdBy) pinned a \(pinType.displayName)"
            : "\(createdBy) pinned a \(pinType.displayName) — \(title)"

        pinSystemCard(
            icon: "mappin.fill",
            accentColor: pinType.color,
            text: text,
            subtitle: channelsSubtitle(from: channelsCSV),
            timestamp: message.relativeTimestamp
        )
        .contentShape(Rectangle())
        .onTapGesture {
            NotificationCenter.default.post(name: .navigateToSiteTab, object: nil)
        }
    }

    /// Pin resolved — green themed slim card
    @ViewBuilder
    private func pinResolvedRow(_ message: BitchatMessage) -> some View {
        let parts = message.content
            .replacingOccurrences(of: "[PIN_RESOLVED:", with: "")
            .replacingOccurrences(of: "]", with: "")
            .components(separatedBy: ":")
        let resolvedBy = parts.first ?? "Someone"
        let title = parts.count > 1 ? parts[1] : ""
        let greenColor = Color(red: 0.204, green: 0.780, blue: 0.349) // #34C759

        let text = title.isEmpty
            ? "\(resolvedBy) resolved a pin"
            : "\(resolvedBy) resolved — \(title)"

        pinSystemCard(
            icon: "checkmark.circle.fill",
            accentColor: greenColor,
            text: text,
            subtitle: nil,
            timestamp: message.relativeTimestamp
        )
    }

    /// Pin deleted — red themed slim card
    @ViewBuilder
    private func pinDeletedRow(_ message: BitchatMessage) -> some View {
        let parts = message.content
            .replacingOccurrences(of: "[PIN_DELETED:", with: "")
            .replacingOccurrences(of: "]", with: "")
            .components(separatedBy: ":")
        let deletedBy = parts.first ?? "Someone"
        let title = parts.count > 1 ? parts[1] : ""
        let redColor = Color(red: 0.898, green: 0.282, blue: 0.302) // #E5484D

        let text = title.isEmpty
            ? "\(deletedBy) removed a pin"
            : "\(deletedBy) removed a pin — \(title)"

        pinSystemCard(
            icon: "trash.fill",
            accentColor: redColor,
            text: text,
            subtitle: nil,
            timestamp: message.relativeTimestamp
        )
    }

    /// Pin expired — grey themed slim card
    @ViewBuilder
    private func pinExpiredRow(_ message: BitchatMessage) -> some View {
        let title = message.content
            .replacingOccurrences(of: "[PIN_EXPIRED:", with: "")
            .replacingOccurrences(of: "]", with: "")
        let greyColor = Color(red: 0.541, green: 0.557, blue: 0.588) // #8A8E96

        let text = title.isEmpty ? "Pin expired" : "Pin expired — \(title)"

        pinSystemCard(
            icon: "clock.fill",
            accentColor: greyColor,
            text: text,
            subtitle: nil,
            timestamp: message.relativeTimestamp
        )
    }

    // mediaMessageRow replaced by bubbleWrappedView + mediaContentView

    private func expandWindow(ifNeededFor message: BitchatMessage,
                              allMessages: [BitchatMessage],
                              privatePeer: PeerID?,
                              proxy: ScrollViewProxy) {
        let step = TransportConfig.uiWindowStepCount
        let contextKey: String = {
            if let peer = privatePeer { return "dm:\(peer)" }
            switch locationManager.selectedChannel {
            case .mesh: return "mesh"
            case .location(let ch): return "geo:\(ch.geohash)"
            }
        }()
        let preserveID = "\(contextKey)|\(message.id)"

        if let peer = privatePeer {
            let current = windowCountPrivate[peer] ?? TransportConfig.uiWindowInitialCountPrivate
            let newCount = min(allMessages.count, current + step)
            guard newCount != current else { return }
            windowCountPrivate[peer] = newCount
            DispatchQueue.main.async {
                proxy.scrollTo(preserveID, anchor: .top)
            }
        } else {
            let current = windowCountPublic
            let newCount = min(allMessages.count, current + step)
            guard newCount != current else { return }
            windowCountPublic = newCount
            DispatchQueue.main.async {
                proxy.scrollTo(preserveID, anchor: .top)
            }
        }
    }

    var recordingIndicator: some View {
        let amberColor = Color(red: 0.961, green: 0.620, blue: 0.043) // #E8960C

        return HStack(spacing: 12) {
            Image(systemName: "waveform.circle.fill")
                .foregroundColor(amberColor)
                .font(.bitchatSystem(size: 20))
            Text("Recording... \(formattedRecordingDuration())")
                .font(.bitchatSystem(size: 13, design: .monospaced))
                .foregroundColor(amberColor)
            Spacer()
            Button(action: cancelVoiceRecording) {
                Label("Cancel", systemImage: "xmark.circle")
                    .labelStyle(.iconOnly)
                    .font(.bitchatSystem(size: 18))
                    .foregroundColor(amberColor)
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(amberColor.opacity(0.15))
        )
    }

    private var trimmedMessageText: String {
        messageText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var shouldShowMediaControls: Bool {
        if let peer = viewModel.selectedPrivateChatPeer, !(peer.isGeoDM || peer.isGeoChat) {
            return true
        }
        switch locationManager.selectedChannel {
        case .mesh:
            return true
        case .location:
            return false
        }
    }

    private var shouldShowVoiceControl: Bool {
        if let peer = viewModel.selectedPrivateChatPeer, !(peer.isGeoDM || peer.isGeoChat) {
            return true
        }
        switch locationManager.selectedChannel {
        case .mesh:
            return true
        case .location:
            return false
        }
    }

    private var composerAccentColor: Color {
        viewModel.selectedPrivateChatPeer != nil ? Color.orange : textColor
    }

    // MARK: - Location Drop Button

    #if os(iOS)
    var locationDropButton: some View {
        Button {
            showLocationDropForm = true
        } label: {
            ZStack {
                // Pulsing ring
                Circle()
                    .stroke(Color(red: 0.910, green: 0.588, blue: 0.047).opacity(0.30), lineWidth: 1.5)
                    .frame(width: 32, height: 32)
                    .scaleEffect(locationDropPulse ? 1.2 : 1.0)
                    .opacity(locationDropPulse ? 0 : 1)
                    .animation(
                        .easeInOut(duration: 2.0).repeatForever(autoreverses: false),
                        value: locationDropPulse
                    )

                // Filled button
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 28))
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.black, Color(red: 0.910, green: 0.588, blue: 0.047))
            }
            .frame(width: 32, height: 32)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Drop location")
        .onAppear { locationDropPulse = true }
    }

    // MARK: - Attachment Plus Button

    var attachmentPlusButton: some View {
        // Matches micButtonView exactly: 52pt circle, 52pt frame, 22pt bold icon
        Button {
            withAnimation(.easeOut(duration: 0.2)) {
                showAttachmentMenu.toggle()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(secondaryTextColor.opacity(0.3))
                    .frame(width: 52, height: 52)
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(showAttachmentMenu ? 45 : 0))
                    .animation(.easeOut(duration: 0.2), value: showAttachmentMenu)
            }
            .frame(width: 52, height: 52)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(showAttachmentMenu ? "Close attachment menu" : "Open attachment menu")
    }

    // MARK: - Attachment Menu Row

    var attachmentMenuRow: some View {
        VStack(spacing: 0) {
            // Top border
            Rectangle()
                .fill(Color(red: 0.165, green: 0.173, blue: 0.188)) // #2A2C30
                .frame(height: 1)

            HStack(spacing: 8) {
                // File button
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showAttachmentMenu = false
                    }
                    showDocumentPicker = true
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: "paperclip")
                            .font(.system(size: 20))
                            .foregroundColor(Color(red: 0.541, green: 0.557, blue: 0.588)) // #8A8E96
                        Text("File")
                            .font(.bitchatSystem(size: 11))
                            .foregroundColor(Color(red: 0.541, green: 0.557, blue: 0.588)) // #8A8E96
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(red: 0.141, green: 0.149, blue: 0.157)) // #242628
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color(red: 0.165, green: 0.173, blue: 0.188), lineWidth: 1) // #2A2C30
                    )
                }
                .buttonStyle(.plain)

                // Photo button
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showAttachmentMenu = false
                    }
                    showPhotoSourceSheet = true
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color(red: 0.541, green: 0.557, blue: 0.588)) // #8A8E96
                        Text("Photo")
                            .font(.bitchatSystem(size: 11))
                            .foregroundColor(Color(red: 0.541, green: 0.557, blue: 0.588)) // #8A8E96
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(red: 0.141, green: 0.149, blue: 0.157)) // #242628
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color(red: 0.165, green: 0.173, blue: 0.188), lineWidth: 1) // #2A2C30
                    )
                }
                .buttonStyle(.plain)

                // Location Drop button
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showAttachmentMenu = false
                    }
                    showLocationDropForm = true
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color(red: 0.910, green: 0.588, blue: 0.047)) // amber
                        Text("Location")
                            .font(.bitchatSystem(size: 11))
                            .foregroundColor(Color(red: 0.541, green: 0.557, blue: 0.588)) // #8A8E96
                    }
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(red: 0.141, green: 0.149, blue: 0.157)) // #242628
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color(red: 0.165, green: 0.173, blue: 0.188), lineWidth: 1) // #2A2C30
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .background(Color(red: 0.102, green: 0.110, blue: 0.125)) // #1A1C20
    }
    #endif

    var documentButton: some View {
        Image(systemName: "paperclip")
            .font(.system(size: 20, weight: .medium))
            .foregroundColor(secondaryTextColor)
            .frame(width: 48, height: 48)
            .contentShape(Circle())
            .onTapGesture {
                showDocumentPicker = true
            }
            .accessibilityLabel("Attach document")
    }

    var attachmentButton: some View {
        #if os(iOS)
        Image(systemName: "camera.fill")
            .font(.system(size: 20, weight: .medium))
            .foregroundColor(secondaryTextColor)
            .frame(width: 48, height: 48)
            .contentShape(Circle())
            .onTapGesture {
                showPhotoSourceSheet = true
            }
            .accessibilityLabel("Attach photo")
        #else
        Button(action: {
            imagePickerTargetPeer = viewModel.selectedPrivateChatPeer
            showMacImagePicker = true
        }) {
            Image(systemName: "photo.fill")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(secondaryTextColor)
                .frame(width: 48, height: 48)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Choose photo")
        #endif
    }

    // MARK: - Media Previews

    @ViewBuilder
    private func photoPreview(photoURL: URL) -> some View {
        HStack(spacing: 8) {
            // Thumbnail
            #if os(iOS)
            if let uiImage = UIImage(contentsOfFile: photoURL.path) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            #elseif os(macOS)
            if let nsImage = NSImage(contentsOf: photoURL) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            #endif

            Text("Photo ready to send")
                .font(.bitchatSystem(size: 14))
                .foregroundColor(textColor)

            Spacer()

            // Cancel button
            Button(action: {
                // Clean up the temp file
                try? FileManager.default.removeItem(at: photoURL)
                pendingPhotoURL = nil
                pendingPhotoTargetPeer = nil
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.bitchatSystem(size: 20))
                    .foregroundColor(secondaryTextColor)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Cancel photo")
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(inputBackgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(red: 0.961, green: 0.620, blue: 0.043).opacity(0.3), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func voiceNotePreview(voiceURL: URL) -> some View {
        HStack(spacing: 12) {
            // Use existing VoiceNoteView for preview playback
            VoiceNoteView(
                url: voiceURL,
                isSending: false,
                sendProgress: nil,
                onCancel: nil
            )
            .frame(maxWidth: .infinity)

            // Cancel button
            Button(action: {
                // Clean up the temp file
                try? FileManager.default.removeItem(at: voiceURL)
                pendingVoiceNoteURL = nil
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.bitchatSystem(size: 24))
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Cancel voice note")
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func documentPreview() -> some View {
        let isTooLarge = pendingDocumentSize > Int64(FileTransferLimits.maxPayloadBytes)

        HStack(spacing: 10) {
            Image(systemName: "doc.fill")
                .font(.system(size: 24))
                .foregroundColor(Color(red: 0.910, green: 0.588, blue: 0.047))

            VStack(alignment: .leading, spacing: 2) {
                Text(pendingDocumentName)
                    .font(.bitchatSystem(size: 14, weight: .bold))
                    .foregroundColor(textColor)
                    .lineLimit(1)

                if pendingDocumentSize > 0 {
                    Text(DocumentMessageCard.formatFileSize(pendingDocumentSize))
                        .font(.bitchatSystem(size: 12))
                        .foregroundColor(secondaryTextColor)
                }

                if isTooLarge {
                    Text("File too large (max 1MB)")
                        .font(.bitchatSystem(size: 12, weight: .semibold))
                        .foregroundColor(.red)
                }
            }

            Spacer()

            Button(action: {
                if let url = pendingDocumentURL {
                    try? FileManager.default.removeItem(at: url)
                }
                pendingDocumentURL = nil
                pendingDocumentName = ""
                pendingDocumentSize = 0
                pendingDocumentTargetPeer = nil
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.bitchatSystem(size: 20))
                    .foregroundColor(secondaryTextColor)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Cancel document")
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(inputBackgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isTooLarge ? Color.red.opacity(0.5) : Color(red: 0.961, green: 0.620, blue: 0.043).opacity(0.3), lineWidth: 1)
        )
    }

    @ViewBuilder
    var sendOrMicButton: some View {
        let hasText = !trimmedMessageText.isEmpty
        let hasPendingMedia = pendingPhotoURL != nil || pendingVoiceNoteURL != nil || (pendingDocumentURL != nil && pendingDocumentSize <= Int64(FileTransferLimits.maxPayloadBytes))
        let shouldShowSend = hasText || hasPendingMedia

        if shouldShowVoiceControl {
            ZStack {
                micButtonView
                    .opacity(shouldShowSend ? 0 : 1)
                    .allowsHitTesting(!shouldShowSend)
                sendButtonView(enabled: shouldShowSend)
                    .opacity(shouldShowSend ? 1 : 0)
                    .allowsHitTesting(shouldShowSend)
            }
            .frame(width: 52, height: 52)
        } else {
            sendButtonView(enabled: shouldShowSend)
                .frame(width: 52, height: 52)
        }
    }

    private var micButtonView: some View {
        let isActive = isRecordingVoiceNote || isPreparingVoiceNote
        let amberColor = Color(red: 0.961, green: 0.620, blue: 0.043) // #E8960C

        return ZStack {
            Circle()
                .fill(isActive ? amberColor : secondaryTextColor.opacity(0.3))
                .frame(width: 52, height: 52)
            Image(systemName: "mic.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(width: 52, height: 52)
        .contentShape(Circle())
        .overlay(
            Color.clear
                .contentShape(Circle())
                .highPriorityGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in startVoiceRecording() }
                        .onEnded { _ in finishVoiceRecording(send: true) }
                )
        )
        .accessibilityLabel("Hold to record a voice note")
    }

    private func sendButtonView(enabled: Bool) -> some View {
        return Button(action: sendMessage) {
            ZStack {
                Circle()
                    .fill(enabled ? selfBubbleColor : secondaryTextColor.opacity(0.3))
                    .frame(width: 52, height: 52)
                Image(systemName: "arrow.up")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .frame(width: 52, height: 52)
        .accessibilityLabel(
            String(localized: "content.accessibility.send_message", comment: "Accessibility label for the send message button")
        )
        .accessibilityHint(
            enabled
            ? String(localized: "content.accessibility.send_hint_ready", comment: "Hint prompting the user to send the message")
            : String(localized: "content.accessibility.send_hint_empty", comment: "Hint prompting the user to enter a message")
        )
    }

    func formattedRecordingDuration() -> String {
        let clamped = max(0, recordingDuration)
        let totalMilliseconds = Int((clamped * 1000).rounded())
        let minutes = totalMilliseconds / 60_000
        let seconds = (totalMilliseconds % 60_000) / 1_000
        let centiseconds = (totalMilliseconds % 1_000) / 10
        return String(format: "%02d:%02d.%02d", minutes, seconds, centiseconds)
    }

    func startVoiceRecording() {
        guard shouldShowVoiceControl else { return }
        guard !isRecordingVoiceNote && !isPreparingVoiceNote else { return }
        isPreparingVoiceNote = true
        Task { @MainActor in
            let granted = await VoiceRecorder.shared.requestPermission()
            guard granted else {
                isPreparingVoiceNote = false
                recordingAlertMessage = "Microphone access is required to record voice notes."
                showRecordingAlert = true
                return
            }
            do {
                _ = try VoiceRecorder.shared.startRecording()
                recordingDuration = 0
                recordingStartDate = Date()
                recordingTimer?.invalidate()
                recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                    if let start = recordingStartDate {
                        recordingDuration = Date().timeIntervalSince(start)
                    }
                }
                if let timer = recordingTimer {
                    RunLoop.main.add(timer, forMode: .common)
                }
                isPreparingVoiceNote = false
                isRecordingVoiceNote = true
            } catch {
                SecureLogger.error("Voice recording failed to start: \(error)", category: .session)
                recordingAlertMessage = "Could not start recording."
                showRecordingAlert = true
                VoiceRecorder.shared.cancelRecording()
                isPreparingVoiceNote = false
                isRecordingVoiceNote = false
                recordingStartDate = nil
            }
        }
    }

    func finishVoiceRecording(send: Bool) {
        if isPreparingVoiceNote {
            isPreparingVoiceNote = false
            VoiceRecorder.shared.cancelRecording()
            return
        }
        guard isRecordingVoiceNote else { return }
        isRecordingVoiceNote = false
        recordingTimer?.invalidate()
        recordingTimer = nil
        if let start = recordingStartDate {
            recordingDuration = Date().timeIntervalSince(start)
        }
        recordingStartDate = nil
        if send {
            let minimumDuration: TimeInterval = 1.0
            VoiceRecorder.shared.stopRecording { url in
                DispatchQueue.main.async {
                    guard
                        let url = url,
                        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
                        let fileSize = attributes[.size] as? NSNumber,
                        fileSize.intValue > 0,
                        recordingDuration >= minimumDuration
                    else {
                        if let url = url {
                            try? FileManager.default.removeItem(at: url)
                        }
                        recordingAlertMessage = recordingDuration < minimumDuration
                            ? "Recording is too short."
                            : "Recording failed to save."
                        showRecordingAlert = true
                        return
                    }
                    // Store voice note for preview instead of sending immediately
                    pendingVoiceNoteURL = url
                }
            }
        } else {
            VoiceRecorder.shared.cancelRecording()
        }
    }

    func cancelVoiceRecording() {
        if isPreparingVoiceNote || isRecordingVoiceNote {
            finishVoiceRecording(send: false)
        }
    }

    func handleImportResult(_ result: Result<[URL], Error>, handler: @escaping (URL) async -> Void) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            let needsStop = url.startAccessingSecurityScopedResource()
            Task {
                defer {
                    if needsStop {
                        url.stopAccessingSecurityScopedResource()
                    }
                }
                await handler(url)
            }
        case .failure(let error):
            SecureLogger.error("Media import failed: \(error)", category: .session)
        }
    }


    func applicationFilesDirectory() -> URL? {
        // Cache the directory lookup to avoid repeated FileManager calls during view rendering
        struct Cache {
            static var cachedURL: URL?
            static var didAttempt = false
        }

        if Cache.didAttempt {
            return Cache.cachedURL
        }

        do {
            let base = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let filesDir = base.appendingPathComponent("files", isDirectory: true)
            try FileManager.default.createDirectory(at: filesDir, withIntermediateDirectories: true, attributes: nil)
            Cache.cachedURL = filesDir
            Cache.didAttempt = true
            return filesDir
        } catch {
            SecureLogger.error("Failed to resolve application files directory: \(error)", category: .session)
            Cache.didAttempt = true
            return nil
        }
    }

    #if os(iOS)
    private func handleTakePhoto() {
        // Capture the DM context BEFORE showing the picker
        imagePickerTargetPeer = viewModel.selectedPrivateChatPeer

        requestCameraPermission { granted in
            if granted {
                imagePickerSourceType = .camera
                showImagePicker = true
            } else {
                showCameraPermissionAlert = true
                imagePickerTargetPeer = nil
            }
        }
    }

    private func handleChooseFromLibrary() {
        // Capture the DM context BEFORE showing the picker
        imagePickerTargetPeer = viewModel.selectedPrivateChatPeer
        imagePickerSourceType = .photoLibrary
        showImagePicker = true
    }

    private func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }
    #endif
}

//

struct ImagePreviewView: View {
    let url: URL

    @Environment(\.dismiss) private var dismiss
    #if os(iOS)
    @State private var showExporter = false
    @State private var platformImage: UIImage?
    #else
    @State private var platformImage: NSImage?
    #endif

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack {
                Spacer()
                if let image = platformImage {
                    #if os(iOS)
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding()
                    #else
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding()
                    #endif
                } else {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                }
                Spacer()
                HStack {
                    Button(action: { dismiss() }) {
                        Text("close", comment: "Button to dismiss fullscreen media viewer")
                            .font(.bitchatSystem(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.5), lineWidth: 1))
                    }
                    Spacer()
                    Button(action: saveCopy) {
                        Text("save", comment: "Button to save media to device")
                            .font(.bitchatSystem(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.blue.opacity(0.6)))
                    }
                }
                .padding([.horizontal, .bottom], 24)
            }
        }
        .onAppear(perform: loadImage)
        #if os(iOS)
        .sheet(isPresented: $showExporter) {
            FileExportWrapper(url: url)
        }
        #endif
    }

    private func loadImage() {
        DispatchQueue.global(qos: .userInitiated).async {
            #if os(iOS)
            guard let image = UIImage(contentsOfFile: url.path) else { return }
            #else
            guard let image = NSImage(contentsOf: url) else { return }
            #endif
            DispatchQueue.main.async {
                self.platformImage = image
            }
        }
    }

    private func saveCopy() {
        #if os(iOS)
        showExporter = true
        #else
        Task { @MainActor in
            let panel = NSSavePanel()
            panel.canCreateDirectories = true
            panel.nameFieldStringValue = url.lastPathComponent
            panel.prompt = "save"
            if panel.runModal() == .OK, let destination = panel.url {
                do {
                    if FileManager.default.fileExists(atPath: destination.path) {
                        try FileManager.default.removeItem(at: destination)
                    }
                    try FileManager.default.copyItem(at: url, to: destination)
                } catch {
                    SecureLogger.error("Failed to save image preview copy: \(error)", category: .session)
                }
            }
        }
        #endif
    }

    #if os(iOS)
    private struct FileExportWrapper: UIViewControllerRepresentable {
        let url: URL

        func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
            let controller = UIDocumentPickerViewController(forExporting: [url])
            controller.shouldShowFileExtensions = true
            return controller
        }

        func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    }
#endif
}

#if os(iOS)
// MARK: - Image Picker (Camera or Photo Library)
struct ImagePickerView: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let completion: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = false

        // Use standard full screen - iOS handles safe areas automatically
        picker.modalPresentationStyle = .fullScreen

        // Force dark mode to make safe area bars black instead of white
        picker.overrideUserInterfaceStyle = .dark

        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(completion: completion)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let completion: (UIImage?) -> Void

        init(completion: @escaping (UIImage?) -> Void) {
            self.completion = completion
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            let image = info[.originalImage] as? UIImage
            completion(image)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            completion(nil)
        }
    }
}
#endif

#if os(macOS)
// MARK: - macOS Image Picker
struct MacImagePickerView: View {
    let completion: (URL?) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text("Choose an image")
                .font(.headline)

            Button("Select Image") {
                let panel = NSOpenPanel()
                panel.allowsMultipleSelection = false
                panel.canChooseDirectories = false
                panel.canChooseFiles = true
                panel.allowedContentTypes = [.image, .png, .jpeg, .heic]
                panel.message = "Choose an image to send"

                if panel.runModal() == .OK {
                    completion(panel.url)
                } else {
                    dismiss()
                }
            }
            .buttonStyle(.borderedProminent)

            Button("Cancel") {
                completion(nil)
            }
            .buttonStyle(.bordered)
        }
        .padding(40)
        .frame(minWidth: 300, minHeight: 150)
    }
}
#endif
