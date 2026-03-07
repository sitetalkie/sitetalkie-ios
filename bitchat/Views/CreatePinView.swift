//
// CreatePinView.swift
// bitchat
//
// Sheet for creating a new site location pin.
//

import SwiftUI
import CoreLocation

#if os(iOS)

struct CreatePinView: View {
    @EnvironmentObject var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss

    @ObservedObject private var locationManager = RadarLocationManager.shared

    @State private var selectedType: PinType?
    @State private var title: String = ""
    @State private var pinDescription: String = ""
    @State private var floor: Int = UserDefaults.standard.integer(forKey: "currentFloorNumber")
    @State private var precision: PinPrecision = .precise
    @State private var expiryOption: ExpiryOption = .noExpiry
    @State private var photoImage: UIImage?
    @State private var showPhotoSourcePicker = false
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var showToast = false
    @State private var selectedChannels: Set<String> = ["site"]

    // Design system
    private let backgroundColor = Color(red: 0.055, green: 0.063, blue: 0.071) // #0E1012
    private let cardColor = Color(red: 0.102, green: 0.110, blue: 0.125)       // #1A1C20
    private let borderColor = Color(red: 0.165, green: 0.173, blue: 0.188)     // #2A2C30
    private let textPrimary = Color(red: 0.941, green: 0.941, blue: 0.941)     // #F0F0F0
    private let textSecondary = Color(red: 0.541, green: 0.557, blue: 0.588)   // #8A8E96
    private let amber = Color(red: 0.910, green: 0.588, blue: 0.047)           // #E8960C

    private var canCreate: Bool {
        guard let type = selectedType else { return false }
        let hasTitle = !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasChannels = type == .hazard || !selectedChannels.isEmpty
        return hasTitle && hasChannels
    }

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack {
                        Text("Create Pin")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(textSecondary)
                        }
                    }

                    // Pin type selector — 2x2 grid
                    pinTypeGrid

                    // Channel selector (below pin type)
                    channelSelector

                    // Title field
                    TextField("What's here?", text: $title)
                        .font(.system(size: 16))
                        .foregroundColor(textPrimary)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(cardColor)
                        )
                        .accentColor(amber)

                    // Description field
                    ZStack(alignment: .topLeading) {
                        if pinDescription.isEmpty {
                            Text("Add details...")
                                .font(.system(size: 16))
                                .foregroundColor(textSecondary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 14)
                        }
                        TextEditor(text: $pinDescription)
                            .font(.system(size: 16))
                            .foregroundColor(textPrimary)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 80)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(cardColor)
                    )

                    // Floor selector
                    HStack {
                        Text("Your floor")
                            .font(.system(size: 16))
                            .foregroundColor(textPrimary)
                        Spacer()
                        Stepper("Floor \(floor)", value: $floor, in: -3...50)
                            .font(.system(size: 16))
                            .foregroundColor(textPrimary)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(cardColor)
                    )

                    // Precision selector
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Precision")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(textSecondary)
                            .textCase(.uppercase)

                        HStack(spacing: 8) {
                            ForEach(PinPrecision.allCases, id: \.self) { p in
                                Button(action: { precision = p }) {
                                    Text(p.displayName)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(precision == p ? amber : textSecondary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(cardColor)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 20)
                                                        .stroke(precision == p ? amber : borderColor, lineWidth: 1)
                                                )
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Photo button
                    photoSection

                    // Expiry selector
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Expiry")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(textSecondary)
                            .textCase(.uppercase)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(ExpiryOption.allCases, id: \.self) { opt in
                                    Button(action: { expiryOption = opt }) {
                                        Text(opt.displayName)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(expiryOption == opt ? amber : textSecondary)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .fill(cardColor)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 20)
                                                            .stroke(expiryOption == opt ? amber : borderColor, lineWidth: 1)
                                                    )
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    // Create button
                    Button(action: createPin) {
                        Text("Create Pin")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(canCreate ? (selectedType?.color ?? amber) : Color.gray.opacity(0.3))
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(!canCreate)
                }
                .padding(16)
            }

            // Toast overlay
            if showToast {
                VStack {
                    Spacer()
                    Text("Pin created \u{2713}")
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
                .transition(.move(edge: .bottom).combined(with: .opacity))
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
        .onAppear {
            // Request a single high-accuracy GPS fix for best pin coordinates
            locationManager.requestSingleLocation()
        }
        .sheet(isPresented: $showCamera) {
            ImagePickerView(sourceType: .camera) { image in
                if let image = image { photoImage = image }
                showCamera = false
            }
        }
    }

    // MARK: - Pin Type Grid

    private var pinTypeGrid: some View {
        HStack(spacing: 8) {
            pinTypeCard(.hazard)
            pinTypeCard(.note)
        }
    }

    private func pinTypeCard(_ type: PinType) -> some View {
        Button(action: {
            selectedType = type
            // Auto-set channel defaults
            switch type {
            case .hazard:
                selectedChannels = ["site", "general", "defects", "deliveries"]
            case .note:
                selectedChannels = ["site"]
            default:
                selectedChannels = ["site"]
            }
        }) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.system(size: 24))
                    .foregroundColor(type.color)
                Text(type.displayName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(cardColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedType == type ? type.color : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Channel Selector

    private let channelOptions: [(label: String, value: String)] = [
        ("#site", "site"),
        ("#general", "general"),
        ("#defects", "defects"),
        ("#deliveries", "deliveries"),
    ]

    @ViewBuilder
    private var channelSelector: some View {
        if let type = selectedType {
            VStack(alignment: .leading, spacing: 8) {
                Text("Channels")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(textSecondary)
                    .textCase(.uppercase)

                if type == .hazard {
                    // Hazard pins: all channels selected and locked
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(channelOptions, id: \.value) { option in
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                    Text(option.label)
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(amber)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(cardColor)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(amber, lineWidth: 1)
                                        )
                                )
                            }
                        }
                    }
                    Text("Hazard pins appear on all channels")
                        .font(.system(size: 12))
                        .foregroundColor(textSecondary)
                } else {
                    // Note: multi-select toggle
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(channelOptions, id: \.value) { option in
                                let isSelected = selectedChannels.contains(option.value)
                                Button(action: {
                                    if isSelected {
                                        selectedChannels.remove(option.value)
                                    } else {
                                        selectedChannels.insert(option.value)
                                    }
                                }) {
                                    HStack(spacing: 4) {
                                        if isSelected {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 10, weight: .bold))
                                        }
                                        Text(option.label)
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .foregroundColor(isSelected ? amber : textSecondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(cardColor)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .stroke(isSelected ? amber : borderColor, lineWidth: 1)
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
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
                        Image(systemName: "camera.fill")
                            .font(.system(size: 18))
                            .foregroundColor(amber)
                        Text("Add Photo")
                            .font(.system(size: 16))
                            .foregroundColor(textPrimary)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
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
            }
        }
    }

    // MARK: - Create Pin Action

    private func createPin() {
        guard let type = selectedType else { return }
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        // Capture GPS
        let lat = locationManager.latestLatitude ?? 0
        let lon = locationManager.latestLongitude ?? 0

        // Compress photo
        let jpegData = photoImage?.jpegData(compressionQuality: 0.5)

        // Compute expiry
        let expiresAt: Date? = expiryOption.expiresAt

        // Determine channels: Hazard always ["all"], others use selection
        let pinChannels: [String]
        if type == .hazard {
            pinChannels = ["all"]
        } else {
            pinChannels = Array(selectedChannels)
        }

        let pin = SitePin(
            type: type,
            title: trimmedTitle,
            description: pinDescription.isEmpty ? nil : pinDescription,
            latitude: lat,
            longitude: lon,
            floor: floor,
            createdBy: viewModel.nickname,
            expiresAt: expiresAt,
            photoData: jpegData,
            radius: precision.radiusMetres,
            precision: precision,
            channels: pinChannels
        )

        SitePinManager.shared.addPin(pin)
        broadcastPin(pin)

        // Show toast and dismiss
        withAnimation { showToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            dismiss()
        }
    }

    private func broadcastPin(_ pin: SitePin) {
        // Serialize pin to compact JSON (strip photoData for mesh to keep payload small)
        let lightPin = SitePin(
            id: pin.id,
            type: pin.type,
            title: pin.title,
            description: pin.description,
            latitude: pin.latitude,
            longitude: pin.longitude,
            floor: pin.floor,
            createdBy: pin.createdBy,
            createdAt: pin.createdAt,
            expiresAt: pin.expiresAt,
            isResolved: pin.isResolved,
            photoData: nil, // Strip photo for mesh
            radius: pin.radius,
            precision: pin.precision,
            channels: pin.channels
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [] // compact, no whitespace
        if let data = try? encoder.encode(lightPin),
           let json = String(data: data, encoding: .utf8) {
            let message = "[SITE_PIN:\(json)]"
            viewModel.sendMessage(message)
        }
    }
}

// MARK: - Expiry Option

private enum ExpiryOption: String, CaseIterable {
    case noExpiry
    case twentyFourHours
    case oneWeek
    case untilResolved

    var displayName: String {
        switch self {
        case .noExpiry: return "No expiry"
        case .twentyFourHours: return "24 hours"
        case .oneWeek: return "1 week"
        case .untilResolved: return "Until resolved"
        }
    }

    var expiresAt: Date? {
        switch self {
        case .noExpiry: return nil
        case .twentyFourHours: return Date().addingTimeInterval(86400)
        case .oneWeek: return Date().addingTimeInterval(604800)
        case .untilResolved: return nil
        }
    }
}

#endif
