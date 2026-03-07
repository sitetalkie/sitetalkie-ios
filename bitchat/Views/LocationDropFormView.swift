//
// LocationDropFormView.swift
// bitchat
//
// Bottom sheet form for dropping your location to the current channel or DM.
//

import SwiftUI

#if os(iOS)

struct LocationDropFormView: View {
    @EnvironmentObject var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss

    @ObservedObject private var locationManager = RadarLocationManager.shared

    // Form fields
    @State private var floor: String = ""
    @State private var zone: String = ""
    @State private var selectedLandmarks: Set<String> = []
    @State private var message: String = ""
    @State private var isEmergency: Bool = false
    @State private var photoImage: UIImage?
    @State private var showPhotoSourcePicker = false
    @State private var showImagePicker = false
    @State private var showCamera = false

    // Design system
    private let sheetBackground = Color(red: 0.078, green: 0.086, blue: 0.094) // #141618
    private let cardColor = Color(red: 0.102, green: 0.110, blue: 0.125)       // #1A1C20
    private let borderColor = Color(red: 0.165, green: 0.173, blue: 0.188)     // #2A2C30
    private let textPrimary = Color(red: 0.941, green: 0.941, blue: 0.941)     // #F0F0F0
    private let textSecondary = Color(red: 0.541, green: 0.557, blue: 0.588)   // #8A8E96
    private let subtitleColor = Color(red: 0.353, green: 0.369, blue: 0.400)   // #5A5E66
    private let amber = Color(red: 0.910, green: 0.588, blue: 0.047)           // #E8960C
    private let emergencyRed = Color(red: 0.898, green: 0.282, blue: 0.302)    // #E5484D
    private let dragHandleColor = Color(red: 0.227, green: 0.235, blue: 0.251) // #3A3C40

    private static let landmarks = [
        "Stairwell", "Lift", "Entrance", "Site Office", "Crane",
        "Core", "Plant Room", "Roof", "Car Park", "Scaffold"
    ]

    private var canSend: Bool {
        !floor.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !zone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var sendTarget: String {
        if let dmPeer = viewModel.selectedPrivateChatPeer,
           let name = viewModel.meshService.peerNickname(peerID: dmPeer) {
            return name
        }
        return "#\(viewModel.activeChannel.displayName)"
    }

    var body: some View {
        ZStack {
            sheetBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Drag handle
                RoundedRectangle(cornerRadius: 2)
                    .fill(dragHandleColor)
                    .frame(width: 36, height: 4)
                    .padding(.top, 10)

                // Top amber border
                Rectangle()
                    .fill(amber)
                    .frame(height: 2)
                    .padding(.top, 8)

                // Header
                HStack {
                    Text("\u{1F4CD} Drop Location")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(amber)
                    Spacer()
                    Button("Cancel") { dismiss() }
                        .font(.system(size: 16))
                        .foregroundColor(textSecondary)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                // Subtitle
                Text("Tell your team exactly where you are")
                    .font(.system(size: 11))
                    .foregroundColor(subtitleColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 4)

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Floor field
                        formField(label: "FLOOR / LEVEL") {
                            TextField("e.g. Level 3, B1, Roof", text: $floor)
                                .font(.system(size: 16))
                                .foregroundColor(textPrimary)
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(cardColor)
                                )
                                .accentColor(amber)
                        }

                        // Zone field
                        formField(label: "ZONE / AREA") {
                            TextField("e.g. East side, near M&E riser", text: $zone)
                                .font(.system(size: 16))
                                .foregroundColor(textPrimary)
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(cardColor)
                                )
                                .accentColor(amber)
                        }

                        // Landmark quick picks
                        formField(label: "WHAT ARE YOU NEAR?") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(Self.landmarks, id: \.self) { landmark in
                                        landmarkChip(landmark)
                                    }
                                }
                            }
                        }

                        // Photo section
                        photoSection

                        // Emergency toggle
                        emergencySection

                        // Emergency message (only when toggled on)
                        if isEmergency {
                            formField(label: "MESSAGE") {
                                TextField("e.g. Pipe burst, need help", text: $message)
                                    .font(.system(size: 16))
                                    .foregroundColor(textPrimary)
                                    .padding(14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(cardColor)
                                    )
                                    .accentColor(emergencyRed)
                            }
                        }

                        // Send button
                        Button(action: sendLocationDrop) {
                            Text("\u{1F4CD} Drop Location to \(sendTarget)")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(canSend ? (isEmergency ? emergencyRed : amber) : Color.gray.opacity(0.3))
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(!canSend)
                    }
                    .padding(16)
                }
            }

            // Photo source picker overlay
            if showPhotoSourcePicker {
                PhotoSourcePicker(
                    onTakePhoto: {
                        showPhotoSourcePicker = false
                        showCamera = true
                    },
                    onChooseFromLibrary: {
                        showPhotoSourcePicker = false
                        showImagePicker = true
                    },
                    onCancel: {
                        showPhotoSourcePicker = false
                    }
                )
                .zIndex(100)
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showImagePicker) {
            ImagePickerView(sourceType: .photoLibrary) { image in
                if let image = image { photoImage = image }
                showImagePicker = false
            }
        }
        .sheet(isPresented: $showCamera) {
            ImagePickerView(sourceType: .camera) { image in
                if let image = image { photoImage = image }
                showCamera = false
            }
        }
    }

    // MARK: - Form Field Wrapper

    private func formField<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(textSecondary)
                .tracking(1)
            content()
        }
    }

    // MARK: - Landmark Chip

    private func landmarkChip(_ landmark: String) -> some View {
        let isSelected = selectedLandmarks.contains(landmark)
        return Button {
            if isSelected {
                selectedLandmarks.remove(landmark)
            } else {
                selectedLandmarks.insert(landmark)
            }
        } label: {
            Text(landmark)
                .font(.system(size: 12))
                .foregroundColor(isSelected ? amber : textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? amber.opacity(0.15) : cardColor)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(isSelected ? amber : borderColor, lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Photo Section

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let image = photoImage {
                HStack(spacing: 12) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    Button(action: { photoImage = nil }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(textSecondary)
                    }
                    Spacer()
                }
            } else {
                Button(action: { showPhotoSourcePicker = true }) {
                    HStack(spacing: 10) {
                        Text("\u{1F4F7}")
                            .font(.system(size: 18))
                        Text("Attach a photo of where you are")
                            .font(.system(size: 14))
                            .foregroundColor(textPrimary)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(cardColor)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
                                    .foregroundColor(borderColor)
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Emergency Section

    private var emergencySection: some View {
        HStack(spacing: 12) {
            Text("\u{1F6A8}")
                .font(.system(size: 18))
            Text("This is an emergency")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(textPrimary)
            Spacer()
            Toggle("", isOn: $isEmergency)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: emergencyRed))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(cardColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isEmergency ? emergencyRed.opacity(0.5) : borderColor, lineWidth: 1)
                )
        )
    }

    // MARK: - Send Action

    private func sendLocationDrop() {
        let trimmedFloor = floor.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedZone = zone.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedFloor.isEmpty, !trimmedZone.isEmpty else { return }

        let nearLandmark: String? = selectedLandmarks.isEmpty
            ? nil
            : selectedLandmarks.sorted().joined(separator: " / ")

        let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)

        let drop = LocationDrop(
            id: UUID(),
            senderID: viewModel.meshService.myPeerID.id,
            senderName: viewModel.nickname,
            senderTrade: UserDefaults.standard.string(forKey: "com.sitetalkie.user.trade"),
            timestamp: Date(),
            floor: trimmedFloor,
            zone: trimmedZone,
            nearLandmark: nearLandmark,
            message: trimmedMessage.isEmpty ? nil : trimmedMessage,
            hasPhoto: photoImage != nil,
            latitude: locationManager.latestLatitude,
            longitude: locationManager.latestLongitude,
            isEmergency: isEmergency
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = []
        if let data = try? encoder.encode(drop),
           let json = String(data: data, encoding: .utf8) {
            let taggedMessage = "[LOCATION_DROP:\(json)]"
            viewModel.sendMessage(taggedMessage)
        }

        dismiss()
    }
}

#endif
