import SwiftUI

/// Sheet for composing and sending an SOS alert to everyone on the mesh.
struct SiteAlertComposerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: ChatViewModel
    @EnvironmentObject var alertNavigationState: AlertNavigationState
    @ObservedObject private var locationManager = RadarLocationManager.shared

    @State private var selectedType: SiteAlertType? = nil
    @State private var detailText = ""
    @State private var zoneText = ""
    @State private var selectedLandmark: String? = nil
    @State private var showConfirmation = false
    @State private var alertFloor: Int = UserDefaults.standard.integer(forKey: "currentFloorNumber")
    @State private var gpsLatitude: Double? = nil
    @State private var gpsLongitude: Double? = nil

    private let backgroundColor = Color(red: 0.055, green: 0.063, blue: 0.071)  // #0E1012
    private let cardSurface = Color(red: 0.102, green: 0.110, blue: 0.125)      // #1A1C20
    private let borderColor = Color(red: 0.165, green: 0.173, blue: 0.188)      // #2A2C30
    private let textPrimary = Color(red: 0.941, green: 0.941, blue: 0.941)      // #F0F0F0
    private let textSecondary = Color(red: 0.541, green: 0.557, blue: 0.588)    // #8A8E96
    private let textTertiary = Color(red: 0.353, green: 0.369, blue: 0.400)     // #5A5E66
    private let amberColor = Color(red: 0.910, green: 0.588, blue: 0.047)       // #E8960C
    private let warningRed = Color(red: 0.898, green: 0.282, blue: 0.302)       // #E5484D
    private let elevatedColor = Color(red: 0.141, green: 0.149, blue: 0.157)    // #242628

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    private let landmarks = [
        "Main entrance", "Stairwell", "Lift", "Loading bay",
        "Roof", "Basement", "Car park", "Canopy"
    ]

    var body: some View {
        NavigationView {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 20) {
                        // Close button row
                        HStack {
                            Button {
                                dismiss()
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(elevatedColor)
                                        .frame(width: 36, height: 36)
                                    Image(systemName: "xmark")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(textSecondary)
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Close")
                            Spacer()
                        }

                        // Header
                        headerSection

                        // Emergency type grid
                        alertTypeGrid(proxy: proxy)

                        // Floor selector
                        floorSelector

                        // Location section
                        locationSection
                            .id("locationSection")

                        // Optional message field
                        detailField

                        // Send button
                        sendButton

                        // Cancel link
                        Button("Cancel") {
                            dismiss()
                        }
                        .font(.bitchatSystem(size: 16))
                        .foregroundColor(textSecondary)
                        .padding(.bottom, 24)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                }
            }
            .background(backgroundColor.ignoresSafeArea())
            .navigationBarHidden(true)
            .onAppear {
                gpsLatitude = locationManager.latestLatitude
                gpsLongitude = locationManager.latestLongitude
            }
            .onReceive(locationManager.$location) { loc in
                if let loc {
                    gpsLatitude = loc.coordinate.latitude
                    gpsLongitude = loc.coordinate.longitude
                }
            }
        }
        .alert(
            confirmationTitle,
            isPresented: $showConfirmation
        ) {
            Button("Cancel", role: .cancel) {}
            Button("Send") {
                sendAlert()
            }
            .tint(warningRed)
        } message: {
            Text("This cannot be undone. All nearby devices will be alerted.")
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "light.beacon.max.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(warningRed)
                Text("EMERGENCY TYPE")
                    .font(.bitchatSystem(size: 18, weight: .bold))
                    .foregroundColor(warningRed)
            }

            Text("Broadcasts to all devices on mesh")
                .font(.bitchatSystem(size: 14))
                .foregroundColor(textSecondary)
        }
    }

    // MARK: - Alert Type Grid

    private func alertTypeGrid(proxy: ScrollViewProxy) -> some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(SiteAlertType.composerTypes) { alertType in
                alertTypeButton(alertType, proxy: proxy)
            }
        }
    }

    private func alertTypeButton(_ alertType: SiteAlertType, proxy: ScrollViewProxy) -> some View {
        let isSelected = selectedType == alertType
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedType = alertType
            }
            withAnimation(.easeOut(duration: 0.3)) {
                proxy.scrollTo("locationSection", anchor: .top)
            }
        } label: {
            HStack(spacing: 0) {
                // Coloured left border
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(alertType.color)
                    .frame(width: 3)
                    .padding(.vertical, 8)

                HStack(spacing: 10) {
                    Image(systemName: alertType.icon)
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? .white : alertType.color)

                    Text(alertType.displayName)
                        .font(.bitchatSystem(size: 14, weight: .semibold))
                        .foregroundColor(isSelected ? .white : textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 80)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? alertType.color.opacity(0.25) : cardSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(isSelected ? amberColor : borderColor, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Floor Selector

    private var floorSelector: some View {
        HStack(spacing: 12) {
            Text("Your floor")
                .font(.bitchatSystem(size: 14))
                .foregroundColor(textSecondary)

            Spacer()

            Button {
                if alertFloor > -3 { alertFloor -= 1 }
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(textSecondary)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Text("Floor \(alertFloor)")
                .font(.bitchatSystem(size: 14, weight: .medium))
                .foregroundColor(.white)
                .frame(minWidth: 60)

            Button {
                if alertFloor < 50 { alertFloor += 1 }
            } label: {
                Image(systemName: "chevron.up")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(textSecondary)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(cardSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )
    }

    // MARK: - Location Section

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("YOUR LOCATION")
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(textTertiary)
                .tracking(1.2)

            // Zone/Area text field
            TextField("e.g. East wing, near lift", text: $zoneText)
                .font(.bitchatSystem(size: 16))
                .foregroundColor(textPrimary)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(cardSurface)
                )

            // Landmark quick-picks
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(landmarks, id: \.self) { landmark in
                        let isSelected = selectedLandmark == landmark
                        Button {
                            if isSelected {
                                selectedLandmark = nil
                                zoneText = ""
                            } else {
                                selectedLandmark = landmark
                                zoneText = landmark
                            }
                        } label: {
                            Text(landmark)
                                .font(.bitchatSystem(size: 11))
                                .foregroundColor(isSelected ? amberColor : textSecondary)
                                .padding(.horizontal, 14)
                                .frame(height: 36)
                                .background(
                                    Capsule()
                                        .fill(elevatedColor)
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(isSelected ? amberColor : Color.clear, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // GPS status
            if let lat = gpsLatitude, let lon = gpsLongitude {
                Text("GPS: \(String(format: "%.4f", lat)), \(String(format: "%.4f", lon))")
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .foregroundColor(textTertiary)
            } else {
                Text("GPS: Locating...")
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .foregroundColor(textTertiary)
                    .opacity(0.6)
            }
        }
    }

    // MARK: - Detail Field

    private var detailField: some View {
        TextField("Add details (optional)...", text: $detailText, axis: .vertical)
            .font(.bitchatSystem(size: 16))
            .foregroundColor(textPrimary)
            .padding(12)
            .lineLimit(3...6)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(cardSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(borderColor, lineWidth: 1)
            )
    }

    // MARK: - Send Button

    private var sendButton: some View {
        Button {
            showConfirmation = true
        } label: {
            Text("SEND SOS")
                .font(.bitchatSystem(size: 20, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(warningRed)
                )
        }
        .buttonStyle(.plain)
        .disabled(selectedType == nil)
        .opacity(selectedType == nil ? 0.4 : 1.0)
    }

    // MARK: - Confirmation

    private var confirmationTitle: String {
        guard let type = selectedType else { return "Send SOS?" }
        return "Send \(type.displayName) to everyone nearby?"
    }

    // MARK: - Send

    private func sendAlert() {
        guard let type = selectedType else { return }
        let prefix = type.messagePrefix(floor: alertFloor)
        let zone = zoneText.trimmingCharacters(in: .whitespacesAndNewlines)
        let detail = detailText.trimmingCharacters(in: .whitespacesAndNewlines)

        var parts: [String] = [prefix]
        if !zone.isEmpty { parts.append(zone) }
        if let lat = gpsLatitude, let lon = gpsLongitude {
            parts.append("GPS:\(String(format: "%.4f", lat)),\(String(format: "%.4f", lon))")
        }
        if !detail.isEmpty { parts.append(detail) }
        let messageContent = parts.joined(separator: " | ")
        viewModel.sendMessage(messageContent)
        dismiss()

        // Auto-open protocol for sender (Part 4)
        if let scenarioId = type.scenarioId {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                alertNavigationState.openProtocol(scenarioId: scenarioId)
            }
        }
    }
}
