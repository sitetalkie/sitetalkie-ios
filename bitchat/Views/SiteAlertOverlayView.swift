import SwiftUI
#if os(iOS)
import AudioToolbox
import UserNotifications
#endif

#if canImport(Translation)
import Translation
#endif

/// Full-screen overlay displayed when a Site Alert is received.
/// Covers the entire screen with the alert colour, pulsing icon, and dismiss button.
struct SiteAlertOverlayView: View {
    let alertType: SiteAlertType
    let floorLabel: String?
    let detail: String
    let senderName: String
    let onDismiss: () -> Void
    let onOpenProtocol: (() -> Void)?

    @State private var pulseScale: CGFloat = 1.0
    @State private var appeared = false
    @State private var translatedDetail: String?

    var body: some View {
        ZStack {
            // Full-screen coloured background
            alertType.color.opacity(0.95)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                // Pulsing icon
                Image(systemName: alertType.icon)
                    .font(.system(size: 80, weight: .bold))
                    .foregroundColor(.white)
                    .scaleEffect(pulseScale)
                    .animation(
                        .easeInOut(duration: 0.8)
                            .repeatForever(autoreverses: true),
                        value: pulseScale
                    )

                // Alert type name
                Text(alertType.displayName.uppercased())
                    .font(.system(size: 36, weight: .black))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                // Floor label
                if let floorLabel = floorLabel {
                    Text(floorLabel)
                        .font(.bitchatSystem(size: 20))
                        .foregroundColor(.white)
                }

                // Detail text
                if !detail.isEmpty {
                    Text(translatedDetail ?? detail)
                        .font(.bitchatSystem(size: 18))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                // Sender info
                Text("Sent by \(senderName)")
                    .font(.bitchatSystem(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.top, 8)

                // Timestamp
                Text("Just now")
                    .font(.bitchatSystem(size: 14))
                    .foregroundColor(.white.opacity(0.5))

                // Open Protocol button (only for alert types with a linked scenario)
                if let openProtocol = onOpenProtocol {
                    Button(action: openProtocol) {
                        HStack(spacing: 8) {
                            Image(systemName: "cross.case.fill")
                                .font(.system(size: 18))
                            Text("Open First Aid Protocol")
                                .font(.bitchatSystem(size: 16, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.white.opacity(0.20))
                        )
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 32)
                    .padding(.top, 8)
                }

                Spacer()

                // Dismiss button
                Button(action: onDismiss) {
                    Text("DISMISS")
                        .font(.bitchatSystem(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(.white, lineWidth: 2)
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
        .overlay { alertAutoTranslateOverlay }
        .transition(.opacity)
        .onAppear {
            pulseScale = 1.2
            playAlertFeedback()

            // GENERAL alerts auto-dismiss after 5 seconds
            if alertType == .general {
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    onDismiss()
                }
            }
        }
    }

    // MARK: - Sound + Haptics

    private func playAlertFeedback() {
        #if os(iOS)
        if alertType.isEmergency {
            // Play loud alert sound
            AudioServicesPlayAlertSound(SystemSoundID(1005))

            // Strong haptic feedback — repeat 3 times
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            for i in 0..<3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.5) {
                    generator.notificationOccurred(.error)
                }
            }
        } else {
            // Standard notification sound for non-emergency (GENERAL)
            AudioServicesPlayAlertSound(SystemSoundID(1007))

            // Single lighter haptic
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        }
        #endif
    }

    @ViewBuilder
    private var alertAutoTranslateOverlay: some View {
        #if os(iOS)
        if #available(iOS 18.0, *),
           !detail.isEmpty,
           TranslationService.shared.isTranslationAvailable,
           !TranslationService.shared.isEnglish {
            AutoTranslateTask(text: detail) { translated in
                translatedDetail = translated
            }
        }
        #endif
    }
}

/// Lightweight "All Clear" overlay that auto-dismisses after 3 seconds.
struct SiteAlertAllClearOverlayView: View {
    let onDismiss: () -> Void

    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            Color(red: 0.204, green: 0.780, blue: 0.349) // #34C759
                .opacity(0.95)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Spacer()

                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 80, weight: .bold))
                    .foregroundColor(.white)
                    .scaleEffect(pulseScale)
                    .animation(
                        .easeInOut(duration: 0.8)
                            .repeatForever(autoreverses: true),
                        value: pulseScale
                    )

                Text("ALL CLEAR")
                    .font(.system(size: 36, weight: .black))
                    .foregroundColor(.white)

                Spacer()
            }
        }
        .transition(.opacity)
        .onAppear {
            pulseScale = 1.2

            #if os(iOS)
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            #endif

            // Auto-dismiss after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                onDismiss()
            }
        }
    }
}

// MARK: - Local Notification Helper

enum SiteAlertNotificationHelper {
    /// Schedules a local notification for a site alert received while backgrounded.
    static func scheduleLocalNotification(alertType: SiteAlertType, detail: String) {
        #if os(iOS)
        let content = UNMutableNotificationContent()
        content.body = detail.isEmpty
            ? "\(alertType.displayName) — Tap to view"
            : "\(alertType.displayName) — \(detail)"

        if alertType.isEmergency {
            content.title = "\u{26A0}\u{FE0F} SITE ALERT"
            content.sound = UNNotificationSound.defaultCritical
            content.interruptionLevel = .critical
        } else {
            content.title = "Site Announcement"
            content.sound = .default
            content.interruptionLevel = .active
        }

        let request = UNNotificationRequest(
            identifier: "site_alert_\(UUID().uuidString)",
            content: content,
            trigger: nil  // Deliver immediately
        )
        UNUserNotificationCenter.current().add(request)
        #endif
    }
}
