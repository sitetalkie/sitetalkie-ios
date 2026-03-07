//
// BitchatApp.swift
// bitchat
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import Tor
import SwiftUI
import UserNotifications

@main
struct BitchatApp: App {
    static let bundleID = Bundle.main.bundleIdentifier ?? "com.sitetalkie.app"
    static let groupID = "group.\(bundleID)"
    
    @StateObject private var chatViewModel: ChatViewModel
    @StateObject private var siteDataStore = SiteDataStore()
    @StateObject private var alertNavigationState = AlertNavigationState()
    @AppStorage("sitetalkie.hasCompletedSetup") private var hasCompletedSetup: Bool = false
    @AppStorage("sitetalkie.bitchatMode") private var bitchatMode: Bool = false
    @State private var showSplash: Bool = true
    // Dashboard auth deep link state
    @State private var showDashboardAuthAlert = false
    @State private var dashboardAuthSessionId: String = ""
    @State private var dashboardAuthChallenge: String = ""
    @State private var dashboardAuthResultMessage: String?
    @State private var showDashboardAuthResult = false
    @State private var dashboardAuthSuccess = false
    #if os(iOS)
    @Environment(\.scenePhase) var scenePhase
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    // Skip the very first .active-triggered Tor restart on cold launch
    @State private var didHandleInitialActive: Bool = false
    @State private var didEnterBackground: Bool = false
    #elseif os(macOS)
    @NSApplicationDelegateAdaptor(MacAppDelegate.self) var appDelegate
    #endif
    
    private let idBridge = NostrIdentityBridge()
    
    init() {
        let keychain = KeychainManager()
        let idBridge = self.idBridge
        let identityManager = SecureIdentityStateManager(keychain)
        _chatViewModel = StateObject(
            wrappedValue: ChatViewModel(
                keychain: keychain,
                idBridge: idBridge,
                identityManager: identityManager,
                transport: BLEService(keychain: keychain, idBridge: idBridge, identityManager: identityManager),
                messagePersistence: MessagesPersistenceService.shared
            )
        )
        
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        // Start GPS early so location is warming up before BLE announces
        RadarLocationManager.shared.start()
        // Warm up georelay directory and refresh if stale (once/day)
        GeoRelayDirectory.shared.prefetchIfNeeded()
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if showSplash {
                    SplashScreenView()
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                withAnimation(.easeOut(duration: 0.4)) {
                                    showSplash = false
                                }
                            }
                        }
                } else if hasCompletedSetup {
                    #if os(iOS)
                    if bitchatMode {
                        BitChatContentView()
                    } else {
                        MainTabView()
                    }
                    #else
                    ContentView()
                    #endif
                } else {
                    SetupView(hasCompletedSetup: $hasCompletedSetup)
                }
            }
                .environmentObject(chatViewModel)
                .environmentObject(siteDataStore)
                .environmentObject(alertNavigationState)
                .onAppear {
                    NotificationDelegate.shared.chatViewModel = chatViewModel
                    // Inject live Noise service into VerificationService to avoid creating new BLE instances
                    VerificationService.shared.configure(with: chatViewModel.meshService.getNoiseService())
                    // Prewarm Nostr identity and QR to make first VERIFY sheet fast
                    let nickname = chatViewModel.nickname
                    DispatchQueue.global(qos: .utility).async {
                        let npub = try? idBridge.getCurrentNostrIdentity()?.npub
                        _ = VerificationService.shared.buildMyQRString(nickname: nickname, npub: npub)
                    }

                    appDelegate.chatViewModel = chatViewModel

                    // Initialize network activation policy; will start Tor/Nostr only when allowed
                    NetworkActivationService.shared.start()
                    
                    // Start presence service (will wait for Tor readiness)
                    GeohashPresenceService.shared.start()

                    // Wire pin expiry → chat system message
                    SitePinManager.shared.onPinExpired = { title in
                        Task { @MainActor in
                            chatViewModel.addPinExpiredMessage(title: title)
                        }
                    }

                    // Re-register pin geofences on launch (also cleans expired pins)
                    SitePinManager.shared.loadPins()
                    SitePinManager.shared.reRegisterAllGeofences()

                    // Check for shared content
                    checkForSharedContent()

                    // Sync site data from Supabase (silent, uses cached data if offline)
                    Task {
                        try? await SiteDataSyncService.shared.sync()
                        try? await BulletinSyncService.shared.sync()
                    }
                    BulletinSyncService.shared.startBackgroundRefresh()
                }
                .onOpenURL { url in
                    handleURL(url)
                }
                .alert("Sign in to SiteTalkie Dashboard", isPresented: $showDashboardAuthAlert) {
                    Button("Cancel", role: .cancel) {}
                    Button("Sign In") { performDashboardAuth() }
                } message: {
                    Text("This links your mesh identity to your referral account.")
                }
                .overlay(alignment: .top) {
                    if showDashboardAuthResult, let msg = dashboardAuthResultMessage {
                        HStack(spacing: 8) {
                            Image(systemName: dashboardAuthSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(dashboardAuthSuccess
                                    ? Color(red: 0.204, green: 0.780, blue: 0.349)
                                    : Color(red: 0.898, green: 0.282, blue: 0.302))
                            Text(msg)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.85))
                        )
                        .padding(.top, 60)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                #if os(iOS)
                .onChange(of: scenePhase) { newPhase in
                    switch newPhase {
                    case .background:
                        // Keep BLE mesh running in background; BLEService adapts scanning automatically
                        // Always send Tor to dormant on background for a clean restart later.
                        TorManager.shared.setAppForeground(false)
                        TorManager.shared.goDormantOnBackground()
                        // Stop geohash sampling while backgrounded
                        Task { @MainActor in
                            chatViewModel.endGeohashSampling()
                        }
                        // Proactively disconnect Nostr to avoid spurious socket errors while Tor is down
                        NostrRelayManager.shared.disconnect()
                        didEnterBackground = true
                        // Save messages to disk when backgrounded
                        Task { @MainActor in
                            chatViewModel.messagePersistence.persistToDisk()
                        }
                    case .active:
                        // Restart services when becoming active
                        chatViewModel.meshService.startServices()
                        TorManager.shared.setAppForeground(true)
                        // On initial cold launch, Tor was just started in onAppear.
                        // Skip the deterministic restart the first time we become active.
                        if didHandleInitialActive && didEnterBackground {
                            if TorManager.shared.isAutoStartAllowed() && !TorManager.shared.isReady {
                                TorManager.shared.ensureRunningOnForeground()
                            }
                        } else {
                            didHandleInitialActive = true
                        }
                        didEnterBackground = false
                        if TorManager.shared.isAutoStartAllowed() {
                            Task.detached {
                                let _ = await TorManager.shared.awaitReady(timeout: 60)
                                await MainActor.run {
                                    // Rebuild proxied sessions to bind to the live Tor after readiness
                                    TorURLSession.shared.rebuild()
                                    // Reconnect Nostr via fresh sessions; will gate until Tor 100%
                                    NostrRelayManager.shared.resetAllConnections()
                                }
                            }
                        }
                        checkForSharedContent()
                    case .inactive:
                        break
                    @unknown default:
                        break
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    // Check for shared content when app becomes active
                    checkForSharedContent()
                }
                #elseif os(macOS)
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                    // App became active
                }
                #endif
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        #endif
    }
    
    private func handleURL(_ url: URL) {
        guard url.scheme == "sitetalkie" else { return }
        switch url.host {
        case "share":
            checkForSharedContent()
        case "auth":
            handleAuthDeepLink(url)
        default:
            break
        }
    }

    private func handleAuthDeepLink(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let sessionId = components.queryItems?.first(where: { $0.name == "session" })?.value,
              let challenge = components.queryItems?.first(where: { $0.name == "challenge" })?.value,
              !sessionId.isEmpty, !challenge.isEmpty else {
            return
        }
        dashboardAuthSessionId = sessionId
        dashboardAuthChallenge = challenge
        showDashboardAuthAlert = true
    }

    private func performDashboardAuth() {
        let sessionId = dashboardAuthSessionId
        let challenge = dashboardAuthChallenge
        let bridge = idBridge
        Task {
            do {
                try await DashboardAuthService.signInToDashboard(
                    sessionId: sessionId,
                    challenge: challenge,
                    idBridge: bridge
                )
                await MainActor.run {
                    dashboardAuthSuccess = true
                    dashboardAuthResultMessage = "Signed in to Dashboard successfully"
                    showDashboardAuthResult = true
                    autoDismissResult()
                }
            } catch {
                await MainActor.run {
                    dashboardAuthSuccess = false
                    dashboardAuthResultMessage = "Sign in failed. Please try again."
                    showDashboardAuthResult = true
                    autoDismissResult()
                }
            }
        }
    }

    private func autoDismissResult() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation { showDashboardAuthResult = false }
        }
    }
    
    private func checkForSharedContent() {
        // Check app group for shared content from extension
        guard let userDefaults = UserDefaults(suiteName: BitchatApp.groupID) else {
            return
        }
        
        guard let sharedContent = userDefaults.string(forKey: "sharedContent"),
              let sharedDate = userDefaults.object(forKey: "sharedContentDate") as? Date else {
            return
        }
        
        // Only process if shared within configured window
        if Date().timeIntervalSince(sharedDate) < TransportConfig.uiShareAcceptWindowSeconds {
            let contentType = userDefaults.string(forKey: "sharedContentType") ?? "text"
            
            // Clear the shared content
            userDefaults.removeObject(forKey: "sharedContent")
            userDefaults.removeObject(forKey: "sharedContentType")
            userDefaults.removeObject(forKey: "sharedContentDate")
            // No need to force synchronize here
            
            // Send the shared content immediately on the main queue
            DispatchQueue.main.async {
                if contentType == "url" {
                    // Try to parse as JSON first
                    if let data = sharedContent.data(using: .utf8),
                       let urlData = try? JSONSerialization.jsonObject(with: data) as? [String: String],
                       let url = urlData["url"] {
                        // Send plain URL
                        self.chatViewModel.sendMessage(url)
                    } else {
                        // Fallback to simple URL
                        self.chatViewModel.sendMessage(sharedContent)
                    }
                } else {
                    self.chatViewModel.sendMessage(sharedContent)
                }
            }
        }
    }
}

#if os(iOS)
final class AppDelegate: NSObject, UIApplicationDelegate {
    weak var chatViewModel: ChatViewModel?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        return true
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        chatViewModel?.applicationWillTerminate()
    }
}
#endif

#if os(macOS)
import AppKit

final class MacAppDelegate: NSObject, NSApplicationDelegate {
    weak var chatViewModel: ChatViewModel?
    
    func applicationWillTerminate(_ notification: Notification) {
        chatViewModel?.applicationWillTerminate()
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
#endif

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    weak var chatViewModel: ChatViewModel?
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let identifier = response.notification.request.identifier
        let userInfo = response.notification.request.content.userInfo
        
        // Check if this is a private message notification
        if identifier.hasPrefix("private-") {
            // Get peer ID from userInfo
            if let peerID = userInfo["peerID"] as? String {
                DispatchQueue.main.async {
                    self.chatViewModel?.startPrivateChat(with: PeerID(str: peerID))
                }
            }
        }
        // Handle bulletin notification tap — deep link to Site tab Bulletin segment
        if identifier.hasPrefix("bulletin-") {
            if let deep = "bitchat://site/bulletin" as String?,
               let url = URL(string: deep) {
                #if os(iOS)
                DispatchQueue.main.async { UIApplication.shared.open(url) }
                #endif
            }
            completionHandler()
            return
        }

        // Handle deeplink (e.g., geohash activity)
        if let deep = userInfo["deeplink"] as? String, let url = URL(string: deep) {
            #if os(iOS)
            DispatchQueue.main.async { UIApplication.shared.open(url) }
            #else
            DispatchQueue.main.async { NSWorkspace.shared.open(url) }
            #endif
        }
        
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let identifier = notification.request.identifier
        let userInfo = notification.request.content.userInfo
        
        // Check if this is a private message notification
        if identifier.hasPrefix("private-") {
            // Get peer ID from userInfo
            if let peerID = userInfo["peerID"] as? String {
                // Don't show notification if the private chat is already open
                // Access main-actor-isolated property via Task
                Task { @MainActor in
                    if self.chatViewModel?.selectedPrivateChatPeer == PeerID(str: peerID) {
                        completionHandler([])
                    } else {
                        completionHandler([.banner, .sound])
                    }
                }
                return
            }
        }
        // Suppress geohash activity notification if we're already in that geohash channel
        if identifier.hasPrefix("geo-activity-"),
           let deep = userInfo["deeplink"] as? String,
           let gh = deep.components(separatedBy: "/").last {
            if case .location(let ch) = LocationChannelManager.shared.selectedChannel, ch.geohash == gh {
                completionHandler([])
                return
            }
        }

        // Suppress public channel notification if viewing that channel
        if identifier.hasPrefix("public-channel-") {
            if let channelID = userInfo["channelID"] as? String {
                Task { @MainActor in
                    guard let vm = self.chatViewModel else {
                        completionHandler([.banner, .sound])
                        return
                    }

                    let isViewingSameChannel: Bool
                    if channelID.hasPrefix("geo:") {
                        let geohash = String(channelID.dropFirst(4))
                        if case .location(let ch) = vm.activeChannel, ch.geohash == geohash {
                            isViewingSameChannel = true
                        } else {
                            isViewingSameChannel = false
                        }
                    } else if channelID == "mesh" {
                        if case .mesh = vm.activeChannel {
                            isViewingSameChannel = true
                        } else {
                            isViewingSameChannel = false
                        }
                    } else {
                        isViewingSameChannel = false
                    }

                    completionHandler(isViewingSameChannel ? [] : [.banner, .sound])
                }
                return
            }
        }

        // Show notification in all other cases
        completionHandler([.banner, .sound])
    }
}

