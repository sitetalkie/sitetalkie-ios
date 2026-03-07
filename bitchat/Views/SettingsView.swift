//
// SettingsView.swift
// bitchat
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import SwiftUI

#if os(iOS)
struct SettingsView: View {
    @EnvironmentObject var viewModel: ChatViewModel
    @State private var editingName = false
    @State private var draftName = ""
    @State private var showAbout = false
    @State private var showTradePicker = false
    @State private var showLanguagePicker = false
    @State private var preferredLanguage: String = ""
    @State private var selectedTrade = ""
    @State private var customTrade = ""
    @State private var dmNotificationsEnabled = true
    @State private var channelNotificationsEnabled = true
    @State private var privateChannelNotificationsEnabled = true
    @State private var ghostModeEnabled = false
    @FocusState private var isNameFocused: Bool
    @State private var currentFloor: Int = 0
    @State private var showFloorPicker = false
    @State private var showEmailAlert = false
    @State private var showDashboardScanner = false
    @State private var referralURL: String = ""
    @State private var loginCodeText: String = ""
    @State private var loginCodeStatus: LoginCodeStatus = .idle
    @State private var loginCodeProcessingId: UUID?
    @State private var showSignInAlert = false
    @State private var pendingAuthSessionId: String = ""
    @State private var pendingAuthChallenge: String = ""
    @State private var showEmergencyHandbook = false
    @State private var showBitchatModeAlert = false
    @AppStorage("sitetalkie.bitchatMode") private var bitchatMode: Bool = false

    private enum LoginCodeStatus {
        case idle
        case loading
        case success
        case invalid
    }

    private let predefinedTrades = [
        "Electrician",
        "Plumber",
        "Mechanical",
        "General Contractor",
        "Site Manager",
        "Architect",
        "Quantity Surveyor",
        "Structural Engineer",
        "MEP Engineer",
        "Health & Safety",
        "Labourer"
    ]

    // Colors
    private let backgroundColor = Color(red: 0.055, green: 0.063, blue: 0.071) // #0E1012
    private let amber = Color(red: 0.910, green: 0.588, blue: 0.047)           // #E8960C
    private let secondaryText = Color(red: 0.353, green: 0.369, blue: 0.400)   // #5A5E66
    private let labelText = Color(red: 0.541, green: 0.557, blue: 0.588)       // #8A8E96
    private let cardBackground = Color(red: 0.102, green: 0.110, blue: 0.125)  // #1A1C20
    private let borderColor = Color(red: 0.165, green: 0.173, blue: 0.188)     // #2A2C30

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        return "v\(version)"
    }

    private var nearbyCount: Int {
        viewModel.allPeers.filter { $0.peerID != viewModel.meshService.myPeerID }.count
    }

    private let red = Color(red: 0.898, green: 0.282, blue: 0.302)     // #E5484D

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Settings")
                        .font(.bitchatSystem(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .frame(height: 56)

                ScrollView {
                    VStack(spacing: 24) {
                        // Section 1: Profile
                        settingsSection(title: "Profile") {
                            // Display name
                            settingsRow {
                                HStack(spacing: 12) {
                                    Image(systemName: "person.fill")
                                        .font(.bitchatSystem(size: 18))
                                        .foregroundColor(amber)
                                        .frame(width: 28)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Display Name")
                                            .font(.bitchatSystem(size: 15, weight: .medium))
                                            .foregroundColor(.white)

                                        if editingName {
                                            TextField("Enter name", text: $draftName)
                                                .font(.bitchatSystem(size: 13))
                                                .foregroundColor(amber)
                                                .textFieldStyle(.plain)
                                                .focused($isNameFocused)
                                                .autocorrectionDisabled(true)
                                                .textInputAutocapitalization(.never)
                                                .onSubmit { saveName() }
                                        } else {
                                            Text(viewModel.nickname.isEmpty ? "Not set" : viewModel.nickname)
                                                .font(.bitchatSystem(size: 13))
                                                .foregroundColor(labelText)
                                        }
                                    }

                                    Spacer()

                                    if editingName {
                                        Button("Done") { saveName() }
                                            .font(.bitchatSystem(size: 14, weight: .medium))
                                            .foregroundColor(amber)
                                            .frame(minWidth: 48, minHeight: 48)
                                    } else {
                                        Button(action: { startEditing() }) {
                                            Image(systemName: "pencil")
                                                .font(.bitchatSystem(size: 16))
                                                .foregroundColor(secondaryText)
                                        }
                                        .frame(minWidth: 48, minHeight: 48)
                                    }
                                }
                            }

                            settingsDivider()

                            // Trade picker
                            Button(action: { showTradePicker = true }) {
                                settingsRow {
                                    HStack(spacing: 12) {
                                        Image(systemName: "hammer.fill")
                                            .font(.bitchatSystem(size: 18))
                                            .foregroundColor(amber)
                                            .frame(width: 28)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Trade")
                                                .font(.bitchatSystem(size: 15, weight: .medium))
                                                .foregroundColor(.white)

                                            Text(selectedTrade.isEmpty ? "Not set" : selectedTrade)
                                                .font(.bitchatSystem(size: 13))
                                                .foregroundColor(labelText)
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.bitchatSystem(size: 13, weight: .semibold))
                                            .foregroundColor(secondaryText)
                                    }
                                }
                            }
                            .buttonStyle(.plain)

                            settingsDivider()

                            // Language preference
                            Button(action: { showLanguagePicker = true }) {
                                settingsRow {
                                    HStack(spacing: 12) {
                                        Image(systemName: "globe")
                                            .font(.bitchatSystem(size: 18))
                                            .foregroundColor(amber)
                                            .frame(width: 28)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Language")
                                                .font(.bitchatSystem(size: 15, weight: .medium))
                                                .foregroundColor(.white)

                                            Text(preferredLanguage.isEmpty ? "Not set" : TranslationService.nativeDisplayName(for: preferredLanguage))
                                                .font(.bitchatSystem(size: 13))
                                                .foregroundColor(labelText)
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.bitchatSystem(size: 13, weight: .semibold))
                                            .foregroundColor(secondaryText)
                                    }
                                }
                            }
                            .buttonStyle(.plain)

                            settingsDivider()

                            // Auto-translate chats
                            settingsRowTall {
                                HStack(spacing: 12) {
                                    Image(systemName: "text.bubble")
                                        .font(.bitchatSystem(size: 18))
                                        .foregroundColor(amber)
                                        .frame(width: 28)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Auto-translate chats")
                                            .font(.bitchatSystem(size: 15, weight: .medium))
                                            .foregroundColor(.white)

                                        if TranslationService.shared.autoTranslateChats {
                                            Text("Incoming messages translated to \(TranslationService.nativeDisplayName(for: preferredLanguage))")
                                                .font(.bitchatSystem(size: 11))
                                                .foregroundColor(labelText)
                                        }
                                    }

                                    Spacer()

                                    Toggle("", isOn: Binding(
                                        get: { TranslationService.shared.autoTranslateChats },
                                        set: { newValue in
                                            TranslationService.shared.autoTranslateChats = newValue
                                        }
                                    ))
                                    .labelsHidden()
                                    .toggleStyle(SwitchToggleStyle(tint: amber))
                                }
                            }

                        }

                        // Section: Safety
                        VStack(alignment: .leading, spacing: 8) {
                            Text("SAFETY")
                                .font(.bitchatSystem(size: 12, weight: .semibold))
                                .foregroundColor(red)
                                .padding(.leading, 4)

                            VStack(spacing: 0) {
                                Button(action: { showEmergencyHandbook = true }) {
                                    settingsRow {
                                        HStack(spacing: 12) {
                                            Image(systemName: "cross.case.fill")
                                                .font(.bitchatSystem(size: 18))
                                                .foregroundColor(amber)
                                                .frame(width: 28)

                                            Text("Emergency Handbook")
                                                .font(.bitchatSystem(size: 15, weight: .medium))
                                                .foregroundColor(.white)

                                            Spacer()

                                            Image(systemName: "chevron.right")
                                                .font(.bitchatSystem(size: 13, weight: .semibold))
                                                .foregroundColor(secondaryText)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(cardBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(borderColor, lineWidth: 1)
                                    )
                            )
                        }

                        // Section 2: Notifications
                        settingsSection(title: "Notifications") {
                            // DM Notifications
                            settingsRowTall {
                                HStack(spacing: 12) {
                                    Image(systemName: "bell.badge.fill")
                                        .font(.bitchatSystem(size: 18))
                                        .foregroundColor(amber)
                                        .frame(width: 28)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("DM Notifications")
                                            .font(.bitchatSystem(size: 15, weight: .medium))
                                            .foregroundColor(.white)

                                        Text("Get notified for direct messages")
                                            .font(.bitchatSystem(size: 13))
                                            .foregroundColor(labelText)
                                    }

                                    Spacer()

                                    Toggle("", isOn: Binding(
                                        get: { dmNotificationsEnabled },
                                        set: { newValue in
                                            dmNotificationsEnabled = newValue
                                            UserDefaults.standard.set(newValue, forKey: "dmNotificationsEnabled")
                                        }
                                    ))
                                    .labelsHidden()
                                    .toggleStyle(SwitchToggleStyle(tint: amber))
                                }
                            }

                            settingsDivider()

                            // Channel Notifications
                            settingsRowTall {
                                HStack(spacing: 12) {
                                    Image(systemName: "bell.fill")
                                        .font(.bitchatSystem(size: 18))
                                        .foregroundColor(amber)
                                        .frame(width: 28)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Channel Notifications")
                                            .font(.bitchatSystem(size: 15, weight: .medium))
                                            .foregroundColor(.white)

                                        Text("Get notified for public messages")
                                            .font(.bitchatSystem(size: 13))
                                            .foregroundColor(labelText)
                                    }

                                    Spacer()

                                    Toggle("", isOn: Binding(
                                        get: { channelNotificationsEnabled },
                                        set: { newValue in
                                            channelNotificationsEnabled = newValue
                                            UserDefaults.standard.set(newValue, forKey: "channelNotificationsEnabled")
                                        }
                                    ))
                                    .labelsHidden()
                                    .toggleStyle(SwitchToggleStyle(tint: amber))
                                }
                            }

                            settingsDivider()

                            // Private Channel Notifications
                            settingsRowTall {
                                HStack(spacing: 12) {
                                    Image(systemName: "bell.and.waves.left.and.right.fill")
                                        .font(.bitchatSystem(size: 18))
                                        .foregroundColor(amber)
                                        .frame(width: 28)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Private Channel Notifications")
                                            .font(.bitchatSystem(size: 15, weight: .medium))
                                            .foregroundColor(.white)

                                        Text("Get notified for private channel messages")
                                            .font(.bitchatSystem(size: 13))
                                            .foregroundColor(labelText)
                                    }

                                    Spacer()

                                    Toggle("", isOn: Binding(
                                        get: { privateChannelNotificationsEnabled },
                                        set: { newValue in
                                            privateChannelNotificationsEnabled = newValue
                                            UserDefaults.standard.set(newValue, forKey: "privateChannelNotificationsEnabled")
                                        }
                                    ))
                                    .labelsHidden()
                                    .toggleStyle(SwitchToggleStyle(tint: amber))
                                }
                            }
                        }

                        // Section 3: Mesh
                        settingsSection(title: "Mesh") {
                            // Nearby users
                            settingsRow {
                                HStack(spacing: 12) {
                                    Image(systemName: "antenna.radiowaves.left.and.right")
                                        .font(.bitchatSystem(size: 18))
                                        .foregroundColor(amber)
                                        .frame(width: 28)

                                    Text("Nearby users")
                                        .font(.bitchatSystem(size: 15, weight: .medium))
                                        .foregroundColor(.white)

                                    Spacer()

                                    Text("\(nearbyCount)")
                                        .font(.bitchatSystem(size: 15))
                                        .foregroundColor(labelText)
                                }
                            }

                            settingsDivider()

                            // Current Floor
                            Button(action: { showFloorPicker = true }) {
                                settingsRow {
                                    HStack(spacing: 12) {
                                        Image(systemName: "building.2.fill")
                                            .font(.bitchatSystem(size: 18))
                                            .foregroundColor(amber)
                                            .frame(width: 28)

                                        Text("Current Floor")
                                            .font(.bitchatSystem(size: 15, weight: .medium))
                                            .foregroundColor(.white)

                                        Spacer()

                                        Text(floorDisplayText)
                                            .font(.bitchatSystem(size: 15))
                                            .foregroundColor(labelText)

                                        Image(systemName: "chevron.right")
                                            .font(.bitchatSystem(size: 13, weight: .semibold))
                                            .foregroundColor(secondaryText)
                                    }
                                }
                            }
                            .buttonStyle(.plain)

                            settingsDivider()

                            // Message range
                            settingsRow {
                                HStack(spacing: 12) {
                                    Image(systemName: "arrow.triangle.branch")
                                        .font(.bitchatSystem(size: 18))
                                        .foregroundColor(amber)
                                        .frame(width: 28)

                                    Text("Message range")
                                        .font(.bitchatSystem(size: 15, weight: .medium))
                                        .foregroundColor(.white)

                                    Spacer()

                                    Text("Up to 7 hops")
                                        .font(.bitchatSystem(size: 15))
                                        .foregroundColor(labelText)
                                }
                            }

                            settingsDivider()

                            // Encryption
                            settingsRow {
                                HStack(spacing: 12) {
                                    Image(systemName: "lock.fill")
                                        .font(.bitchatSystem(size: 18))
                                        .foregroundColor(Color(red: 0.204, green: 0.780, blue: 0.349)) // green
                                        .frame(width: 28)

                                    Text("Encryption")
                                        .font(.bitchatSystem(size: 15, weight: .medium))
                                        .foregroundColor(.white)

                                    Spacer()

                                    Text("End-to-end encrypted")
                                        .font(.bitchatSystem(size: 15))
                                        .foregroundColor(labelText)
                                }
                            }

                            settingsDivider()

                            // Ghost Mode
                            settingsRowTall {
                                HStack(spacing: 12) {
                                    Image(systemName: "eye.slash.fill")
                                        .font(.bitchatSystem(size: 18))
                                        .foregroundColor(amber)
                                        .frame(width: 28)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Ghost Mode")
                                            .font(.bitchatSystem(size: 15, weight: .medium))
                                            .foregroundColor(.white)

                                        Text("Hide yourself from other people's radar")
                                            .font(.bitchatSystem(size: 13))
                                            .foregroundColor(labelText)
                                    }

                                    Spacer()

                                    Toggle("", isOn: Binding(
                                        get: { ghostModeEnabled },
                                        set: { newValue in
                                            ghostModeEnabled = newValue
                                            UserDefaults.standard.set(newValue, forKey: "ghostModeEnabled")
                                        }
                                    ))
                                    .labelsHidden()
                                    .toggleStyle(SwitchToggleStyle(tint: amber))
                                }
                            }
                        }

                        // Section: Refer & Earn + Dashboard Sign In
                        dashboardSection

                        // Section: About
                        settingsSection(title: "About") {
                            // About SiteTalkie
                            Button(action: { showAbout = true }) {
                                settingsRow {
                                    HStack(spacing: 12) {
                                        Image(systemName: "info.circle.fill")
                                            .font(.bitchatSystem(size: 18))
                                            .foregroundColor(amber)
                                            .frame(width: 28)

                                        Text("About SiteTalkie")
                                            .font(.bitchatSystem(size: 15, weight: .medium))
                                            .foregroundColor(.white)

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.bitchatSystem(size: 13, weight: .semibold))
                                            .foregroundColor(secondaryText)
                                    }
                                }
                            }
                            .buttonStyle(.plain)

                            settingsDivider()

                            // Help & FAQ
                            Button(action: {
                                if let url = URL(string: "https://sitetalkie.com/help") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                settingsRowTall {
                                    HStack(spacing: 12) {
                                        Image(systemName: "questionmark.circle.fill")
                                            .font(.bitchatSystem(size: 18))
                                            .foregroundColor(amber)
                                            .frame(width: 28)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Help & FAQ")
                                                .font(.bitchatSystem(size: 15, weight: .medium))
                                                .foregroundColor(.white)
                                            Text("How to use SiteTalkie")
                                                .font(.bitchatSystem(size: 13))
                                                .foregroundColor(labelText)
                                        }

                                        Spacer()

                                        Image(systemName: "arrow.up.right")
                                            .font(.bitchatSystem(size: 13, weight: .semibold))
                                            .foregroundColor(secondaryText)
                                    }
                                }
                            }
                            .buttonStyle(.plain)

                            settingsDivider()

                            // Contact Support
                            Button(action: { openSupportEmail() }) {
                                settingsRowTall {
                                    HStack(spacing: 12) {
                                        Image(systemName: "envelope.fill")
                                            .font(.bitchatSystem(size: 18))
                                            .foregroundColor(amber)
                                            .frame(width: 28)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Contact Support")
                                                .font(.bitchatSystem(size: 15, weight: .medium))
                                                .foregroundColor(.white)
                                            Text("Get help with SiteTalkie")
                                                .font(.bitchatSystem(size: 13))
                                                .foregroundColor(labelText)
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.bitchatSystem(size: 13, weight: .semibold))
                                            .foregroundColor(secondaryText)
                                    }
                                }
                            }
                            .buttonStyle(.plain)

                            settingsDivider()

                            // MEP Desk
                            Button(action: {
                                if let url = URL(string: "https://mepdesk.app") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                settingsRowTall {
                                    HStack(spacing: 12) {
                                        Image(systemName: "wrench.and.screwdriver.fill")
                                            .font(.bitchatSystem(size: 18))
                                            .foregroundColor(amber)
                                            .frame(width: 28)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("From the makers of MEP Desk")
                                                .font(.bitchatSystem(size: 15, weight: .medium))
                                                .foregroundColor(.white)
                                            Text("Engineering tools for building services")
                                                .font(.bitchatSystem(size: 13))
                                                .foregroundColor(labelText)
                                        }

                                        Spacer()

                                        Image(systemName: "arrow.up.right")
                                            .font(.bitchatSystem(size: 13, weight: .semibold))
                                            .foregroundColor(secondaryText)
                                    }
                                }
                            }
                            .buttonStyle(.plain)

                            settingsDivider()

                            // Privacy Policy
                            Button(action: {
                                if let url = URL(string: "https://sitetalkie.com/privacy") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                settingsRow {
                                    HStack(spacing: 12) {
                                        Image(systemName: "hand.raised.fill")
                                            .font(.bitchatSystem(size: 18))
                                            .foregroundColor(amber)
                                            .frame(width: 28)

                                        Text("Privacy Policy")
                                            .font(.bitchatSystem(size: 15, weight: .medium))
                                            .foregroundColor(.white)

                                        Spacer()

                                        Image(systemName: "arrow.up.right")
                                            .font(.bitchatSystem(size: 13, weight: .semibold))
                                            .foregroundColor(secondaryText)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }

                        // Section: Emergency Mesh (no header)
                        Button(action: { showBitchatModeAlert = true }) {
                            HStack(spacing: 12) {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                    .font(.system(size: 20))
                                    .foregroundColor(red)
                                    .frame(width: 28)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Emergency Mesh")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(red)
                                    Text("Switch to BitChat for emergency communication")
                                        .font(.system(size: 12))
                                        .foregroundColor(labelText)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.bitchatSystem(size: 13, weight: .semibold))
                                    .foregroundColor(secondaryText)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(red.opacity(0.08))
                            )
                            .overlay(
                                HStack {
                                    Rectangle()
                                        .fill(red)
                                        .frame(width: 3)
                                    Spacer()
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    // Footer version
                    Text("SiteTalkie \(appVersion)")
                        .font(.bitchatSystem(size: 12))
                        .foregroundColor(secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 32)
                        .padding(.bottom, 24)
                }
            }
        }
        .preferredColorScheme(.dark)
        .alert("About SiteTalkie", isPresented: $showAbout) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("SiteTalkie is a free offline messaging app for construction sites. It uses Bluetooth mesh networking to let teams communicate without cell signal or Wi-Fi.")
        }
        .sheet(isPresented: $showTradePicker) {
            tradePickerSheet
        }
        .sheet(isPresented: $showLanguagePicker) {
            LanguagePickerView(selectedLanguageCode: $preferredLanguage)
        }
        .onChange(of: preferredLanguage) { newValue in
            if !newValue.isEmpty {
                TranslationService.shared.preferredLanguage = newValue
            }
        }
        .sheet(isPresented: $showFloorPicker) {
            floorPickerSheet
        }
        .sheet(isPresented: $showDashboardScanner) {
            DashboardQRScannerView()
        }
        .alert("Email Not Available", isPresented: $showEmailAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Email support@sitetalkie.com for help")
        }
        .alert("Sign in to SiteTalkie Dashboard?", isPresented: $showSignInAlert) {
            Button("Cancel", role: .cancel) {
                loginCodeText = ""
                loginCodeStatus = .idle
            }
            Button("Sign In") { confirmSignIn() }
        } message: {
            Text("This will link your mesh identity to your referral account.")
        }
        .fullScreenCover(isPresented: $showEmergencyHandbook) {
            EmergencyHandbookView()
        }
        .alert("Switch to BitChat?", isPresented: $showBitchatModeAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Switch to BitChat", role: .destructive) {
                bitchatMode = true
            }
        } message: {
            Text("This switches to the BitChat mesh client for emergency communication beyond your site. You can return to SiteTalkie at any time.")
        }
        .onAppear {
            loadTrade()
            preferredLanguage = TranslationService.shared.preferredLanguage
            loadNotificationSettings()
            ghostModeEnabled = UserDefaults.standard.bool(forKey: "ghostModeEnabled")
            currentFloor = UserDefaults.standard.integer(forKey: "currentFloorNumber")
            loadReferralURL()
        }
    }

    // MARK: - Section Components

    @ViewBuilder
    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.bitchatSystem(size: 12, weight: .semibold))
                .foregroundColor(secondaryText)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content()
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(borderColor, lineWidth: 1)
                    )
            )
        }
    }

    @ViewBuilder
    private func settingsRow<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 48)
    }

    @ViewBuilder
    private func settingsRowTall<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func settingsDivider() -> some View {
        Rectangle()
            .fill(borderColor)
            .frame(height: 1)
            .padding(.leading, 56)
    }

    // MARK: - Trade Picker Sheet

    private var tradePickerSheet: some View {
        NavigationView {
            ZStack {
                backgroundColor.ignoresSafeArea()

                List {
                    Section {
                        ForEach(predefinedTrades, id: \.self) { trade in
                            Button(action: {
                                selectedTrade = trade
                                saveTrade()
                                showTradePicker = false
                            }) {
                                HStack {
                                    Text(trade)
                                        .font(.bitchatSystem(size: 15))
                                        .foregroundColor(.white)
                                    Spacer()
                                    if selectedTrade == trade {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(amber)
                                    }
                                }
                            }
                            .listRowBackground(cardBackground)
                        }

                        Button(action: {
                            selectedTrade = customTrade.isEmpty ? "Other" : customTrade
                            saveTrade()
                            showTradePicker = false
                        }) {
                            HStack {
                                TextField("Other (enter custom)", text: $customTrade)
                                    .font(.bitchatSystem(size: 15))
                                    .foregroundColor(.white)
                                    .textFieldStyle(.plain)
                                Spacer()
                                if !predefinedTrades.contains(selectedTrade) && !selectedTrade.isEmpty {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(amber)
                                }
                            }
                        }
                        .listRowBackground(cardBackground)
                    }

                    Section {
                        Button(action: {
                            selectedTrade = ""
                            saveTrade()
                            showTradePicker = false
                        }) {
                            Text("Clear Trade")
                                .font(.bitchatSystem(size: 15))
                                .foregroundColor(.red)
                        }
                        .listRowBackground(cardBackground)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Select Trade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showTradePicker = false
                    }
                    .foregroundColor(amber)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Dashboard Section (Refer + Sign In)

    private var dashboardSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("REFER & EARN")
                .font(.bitchatSystem(size: 12, weight: .semibold))
                .foregroundColor(secondaryText)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                // STEP 1 — Referral QR
                VStack(alignment: .leading, spacing: 12) {
                    Text("1. Share your referral QR")
                        .font(.bitchatSystem(size: 15, weight: .bold))
                        .foregroundColor(amber)

                    if !referralURL.isEmpty {
                        QRCodeImage(data: referralURL, size: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .frame(maxWidth: .infinity)
                    } else {
                        ProgressView()
                            .frame(width: 180, height: 180)
                            .frame(maxWidth: .infinity)
                    }

                    Text("Ask a colleague to scan this on their phone to download SiteTalkie")
                        .font(.bitchatSystem(size: 13))
                        .foregroundColor(labelText)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)

                settingsDivider()

                // STEP 2 — Redeem
                VStack(alignment: .leading, spacing: 12) {
                    Text("2. Sign in to redeem earnings")
                        .font(.bitchatSystem(size: 15, weight: .bold))
                        .foregroundColor(amber)

                    Text("Scan the QR code on dashboard.sitetalkie.com from another device to link your identity and track referrals")
                        .font(.bitchatSystem(size: 13))
                        .foregroundColor(labelText)

                    Button(action: { showDashboardScanner = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "qrcode.viewfinder")
                                .font(.bitchatSystem(size: 16, weight: .semibold))
                            Text("Scan QR")
                                .font(.bitchatSystem(size: 15, weight: .semibold))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(amber)
                        )
                    }
                    .buttonStyle(.plain)

                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)

                // NO SECOND SCREEN divider
                Rectangle()
                    .fill(borderColor)
                    .frame(height: 1)

                VStack(alignment: .leading, spacing: 14) {
                    Text("No second screen?")
                        .font(.bitchatSystem(size: 13, weight: .medium))
                        .foregroundColor(secondaryText)

                    // Step 1: Open Dashboard
                    Button(action: {
                        if let url = URL(string: "https://dashboard.sitetalkie.com/login?nip46=true") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack(spacing: 8) {
                            Text("1.")
                                .font(.bitchatSystem(size: 14, weight: .bold))
                                .foregroundColor(amber)
                            Text("Open Dashboard & Copy Link")
                                .font(.bitchatSystem(size: 14, weight: .semibold))
                                .foregroundColor(amber)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.bitchatSystem(size: 12, weight: .semibold))
                                .foregroundColor(amber)
                        }
                        .frame(height: 40)
                        .padding(.horizontal, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(amber, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)

                    // Step 2: Paste field
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text("2.")
                                .font(.bitchatSystem(size: 14, weight: .bold))
                                .foregroundColor(amber)

                            TextField("Paste login code here...", text: $loginCodeText)
                                .font(.bitchatSystem(size: 14))
                                .foregroundColor(.white)
                                .textFieldStyle(.plain)
                                .autocorrectionDisabled(true)
                                .textInputAutocapitalization(.never)
                                .onSubmit { processLoginCode() }
                                .disabled(loginCodeStatus == .loading)

                            if loginCodeStatus == .loading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                        .frame(height: 40)
                        .padding(.horizontal, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(loginCodeStatus == .invalid ? Color(red: 0.898, green: 0.282, blue: 0.302) : borderColor, lineWidth: 1)
                        )

                        if loginCodeStatus == .invalid {
                            Text("Invalid code")
                                .font(.bitchatSystem(size: 12))
                                .foregroundColor(Color(red: 0.898, green: 0.282, blue: 0.302))
                                .padding(.leading, 4)
                        } else {
                            Text("The login code appears automatically on the dashboard when it opens")
                                .font(.bitchatSystem(size: 12))
                                .foregroundColor(secondaryText)
                                .padding(.leading, 4)
                        }
                    }

                    // Async auth task trigger
                    Color.clear.frame(height: 0)
                        .task(id: loginCodeProcessingId) {
                            guard loginCodeProcessingId != nil else { return }
                            await performLoginCodeAuth()
                        }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(borderColor, lineWidth: 1)
                    )
            )

            Text("When a colleague scans your QR and downloads SiteTalkie, you earn \u{00A3}1 credit after they stay active for 14 days.")
                .font(.bitchatSystem(size: 12))
                .foregroundColor(secondaryText)
                .padding(.horizontal, 4)
        }
    }

    // MARK: - Actions

    private func startEditing() {
        draftName = viewModel.nickname
        editingName = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isNameFocused = true
        }
    }

    private func saveName() {
        viewModel.nickname = draftName
        viewModel.validateAndSaveNickname()
        editingName = false
        isNameFocused = false
    }

    private func loadTrade() {
        selectedTrade = UserDefaults.standard.string(forKey: "com.sitetalkie.user.trade") ?? ""
        if !selectedTrade.isEmpty && !predefinedTrades.contains(selectedTrade) {
            customTrade = selectedTrade
        }
    }

    private func saveTrade() {
        UserDefaults.standard.set(selectedTrade, forKey: "com.sitetalkie.user.trade")
        // Broadcast updated trade to all peers
        viewModel.meshService.sendBroadcastAnnounce()
    }

    private func loadNotificationSettings() {
        let defaults = UserDefaults.standard
        // Default to true if never set
        for key in ["dmNotificationsEnabled", "channelNotificationsEnabled", "privateChannelNotificationsEnabled"] {
            if defaults.object(forKey: key) == nil {
                defaults.set(true, forKey: key)
            }
        }
        dmNotificationsEnabled = defaults.bool(forKey: "dmNotificationsEnabled")
        channelNotificationsEnabled = defaults.bool(forKey: "channelNotificationsEnabled")
        privateChannelNotificationsEnabled = defaults.bool(forKey: "privateChannelNotificationsEnabled")
    }

    private func parseAuthURL(_ urlString: String) -> (sessionId: String, challenge: String)? {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("sitetalkie://auth"),
              let url = URL(string: trimmed),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let sessionId = components.queryItems?.first(where: { $0.name == "session" })?.value,
              let challenge = components.queryItems?.first(where: { $0.name == "challenge" })?.value,
              !sessionId.isEmpty, !challenge.isEmpty else { return nil }
        return (sessionId, challenge)
    }

    private func processLoginCode() {
        guard let params = parseAuthURL(loginCodeText) else {
            if !loginCodeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                loginCodeStatus = .invalid
            }
            return
        }
        pendingAuthSessionId = params.sessionId
        pendingAuthChallenge = params.challenge
        showSignInAlert = true
    }

    private func confirmSignIn() {
        loginCodeStatus = .loading
        loginCodeProcessingId = UUID()
    }

    private func performLoginCodeAuth() async {
        // Use the session/challenge captured at confirmation time.
        let sessionId = pendingAuthSessionId
        let challenge = pendingAuthChallenge
        guard !sessionId.isEmpty, !challenge.isEmpty else {
            loginCodeStatus = .invalid
            return
        }
        let bridge = viewModel.idBridge
        do {
            try await DashboardAuthService.signInToDashboard(
                sessionId: sessionId,
                challenge: challenge,
                idBridge: bridge
            )
            loginCodeStatus = .success
            loginCodeText = ""
            if let dashURL = URL(string: "https://dashboard.sitetalkie.com/login?nip46=true&session=\(sessionId)&challenge=\(challenge)") {
                await UIApplication.shared.open(dashURL)
            }
        } catch {
            loginCodeStatus = .invalid
        }
    }


    private func loadReferralURL() {
        guard referralURL.isEmpty else { return }
        if let identity = try? viewModel.idBridge.getCurrentNostrIdentity() {
            referralURL = "https://sitetalkie.com/refer?ref=\(identity.npub)"
        }
    }

    private var floorDisplayText: String {
        if currentFloor == 0 {
            return "Ground"
        } else if currentFloor < 0 {
            return "B\(abs(currentFloor))"
        } else {
            return "Floor \(currentFloor)"
        }
    }

    private func floorLabel(for floor: Int) -> String {
        if floor == 0 {
            return "Ground (0)"
        } else if floor < 0 {
            return "B\(abs(floor))"
        } else {
            return "Floor \(floor)"
        }
    }

    private func openSupportEmail() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let device = UIDevice.current
        let deviceInfo = "\(device.model) (\(device.systemName) \(device.systemVersion))"
        let subject = "SiteTalkie Support Request"
        let body = "App Version: \(version)\nDevice: \(deviceInfo)\n\nDescribe your issue:\n"
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let mailtoString = "mailto:support@sitetalkie.com?subject=\(encodedSubject)&body=\(encodedBody)"
        if let url = URL(string: mailtoString) {
            UIApplication.shared.open(url) { success in
                if !success {
                    showEmailAlert = true
                }
            }
        }
    }

    // MARK: - Floor Picker Sheet

    private var floorPickerSheet: some View {
        NavigationView {
            ZStack {
                backgroundColor.ignoresSafeArea()

                VStack(spacing: 20) {
                    Text(floorDisplayText)
                        .font(.bitchatSystem(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 24)

                    Picker("Floor", selection: $currentFloor) {
                        ForEach(-3...50, id: \.self) { floor in
                            Text(floorLabel(for: floor))
                                .tag(floor)
                        }
                    }
                    .pickerStyle(.wheel)

                    Text("Set the floor you're currently on. Other users on the radar will see their floor relative to yours.")
                        .font(.bitchatSystem(size: 13))
                        .foregroundColor(labelText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    Spacer()
                }
            }
            .navigationTitle("Current Floor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        UserDefaults.standard.set(currentFloor, forKey: "currentFloorNumber")
                        showFloorPicker = false
                    }
                    .foregroundColor(amber)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
#endif
