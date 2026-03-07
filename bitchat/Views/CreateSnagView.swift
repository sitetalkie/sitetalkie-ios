//
// CreateSnagView.swift
// bitchat
//
// Sheet for reporting new snags. Separate from CreatePinView — snags don't need
// GPS precision or geofencing, they need work details (priority, trade, status).
//

import SwiftUI

#if os(iOS)

struct CreateSnagView: View {
    @EnvironmentObject var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var snagDescription: String = ""
    @State private var priority: SnagPriority = .medium
    @State private var trade: String = ""
    @State private var floor: Int = UserDefaults.standard.integer(forKey: "currentFloorNumber")
    @State private var photoImage: UIImage?
    @State private var showPhotoSourcePicker = false
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var showToast = false
    @State private var isSendingPhoto = false

    private let trades = [
        "Electrician", "Plumber", "Mechanical", "HVAC", "Fire",
        "General Contractor", "Carpenter", "Steelworker",
        "Labourer", "Painter", "Site Manager"
    ]

    // Design system
    private let backgroundColor = Color(red: 0.055, green: 0.063, blue: 0.071) // #0E1012
    private let cardColor = Color(red: 0.102, green: 0.110, blue: 0.125)       // #1A1C20
    private let borderColor = Color(red: 0.165, green: 0.173, blue: 0.188)     // #2A2C30
    private let textPrimary = Color(red: 0.941, green: 0.941, blue: 0.941)     // #F0F0F0
    private let textSecondary = Color(red: 0.541, green: 0.557, blue: 0.588)   // #8A8E96
    private let textTertiary = Color(red: 0.353, green: 0.369, blue: 0.400)    // #5A5E66
    private let amber = Color(red: 0.910, green: 0.588, blue: 0.047)           // #E8960C

    private var canSubmit: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            NavigationView {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Title
                        titleField

                        // Description
                        descriptionField

                        // Priority
                        priorityPicker

                        // Trade
                        tradePicker

                        // Floor
                        floorPicker

                        // Photo
                        photoSection

                        // Submit button
                        submitButton
                    }
                    .padding(16)
                }
                .background(backgroundColor.ignoresSafeArea())
                .navigationTitle("Report Snag")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                            .foregroundColor(textSecondary)
                    }
                }
            }
            .preferredColorScheme(.dark)

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

            // Toast
            if showToast {
                VStack {
                    Spacer()
                    Text("Snag reported")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(Color.black.opacity(0.8)))
                        .padding(.bottom, 40)
                }
                .zIndex(101)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
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

    // MARK: - Title

    private var titleField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("TITLE")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(textSecondary)
                .tracking(0.5)

            TextField("What's the issue?", text: $title)
                .font(.system(size: 16))
                .foregroundColor(textPrimary)
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
    }

    // MARK: - Description

    private var descriptionField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("DESCRIPTION")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(textSecondary)
                .tracking(0.5)

            ZStack(alignment: .topLeading) {
                TextEditor(text: $snagDescription)
                    .font(.system(size: 14))
                    .foregroundColor(textPrimary)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 80)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(cardColor)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(borderColor, lineWidth: 1)
                            )
                    )

                if snagDescription.isEmpty {
                    Text("Add details...")
                        .font(.system(size: 14))
                        .foregroundColor(textTertiary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 18)
                        .allowsHitTesting(false)
                }
            }
        }
    }

    // MARK: - Priority Picker

    private var priorityPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("PRIORITY")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(textSecondary)
                .tracking(0.5)

            HStack(spacing: 10) {
                ForEach(SnagPriority.allCases, id: \.self) { p in
                    Button(action: { priority = p }) {
                        VStack(spacing: 8) {
                            Image(systemName: p.icon)
                                .font(.system(size: 22))
                                .foregroundColor(priority == p ? p.color : textTertiary)
                            Text(p.label)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(priority == p ? textPrimary : textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(cardColor)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(priority == p ? p.color : borderColor, lineWidth: priority == p ? 2 : 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Trade Picker

    private var tradePicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ASSIGN TO TRADE")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(textSecondary)
                .tracking(0.5)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    tradeChip("Any / Unassigned", value: "")
                    ForEach(trades, id: \.self) { t in
                        tradeChip(t, value: t)
                    }
                }
            }
        }
    }

    private func tradeChip(_ label: String, value: String) -> some View {
        Button(action: { trade = value }) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(trade == value ? .white : textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(trade == value ? amber : cardColor)
                        .overlay(
                            Capsule()
                                .stroke(trade == value ? amber : borderColor, lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Floor Picker

    private var floorPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("FLOOR")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(textSecondary)
                .tracking(0.5)

            HStack(spacing: 16) {
                Button(action: { floor -= 1 }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(textSecondary)
                }
                .buttonStyle(.plain)

                VStack(spacing: 2) {
                    Text(floorDisplayLabel)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(textPrimary)
                }
                .frame(minWidth: 100)

                Button(action: { floor += 1 }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(textSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(cardColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(borderColor, lineWidth: 1)
                    )
            )
        }
    }

    private var floorDisplayLabel: String {
        if floor == 0 { return "Ground" }
        if floor < 0 { return "Basement \(abs(floor))" }
        return "Floor \(floor)"
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

    // MARK: - Submit

    private var submitButton: some View {
        Button(action: submitSnag) {
            HStack {
                if isSendingPhoto {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Report Snag")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(canSubmit ? amber : amber.opacity(0.4))
            )
        }
        .buttonStyle(.plain)
        .disabled(!canSubmit || isSendingPhoto)
    }

    private func submitSnag() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        let snagId = UUID().uuidString
        let hasPhoto = photoImage != nil
        let jpegData = photoImage?.jpegData(compressionQuality: 0.5)
        let tradeName: String? = trade.isEmpty ? nil : trade

        // Save to SnagStore
        let snag = Snag(
            id: snagId,
            title: trimmedTitle,
            description: snagDescription.isEmpty ? nil : snagDescription,
            priority: priority,
            trade: tradeName,
            floor: floor,
            createdBy: viewModel.nickname,
            status: .open,
            hasPhoto: hasPhoto,
            photoData: jpegData
        )
        SnagStore.shared.addSnag(snag)

        // Broadcast over mesh
        let message = SnagMessage.wireFormat(
            id: snagId,
            priority: priority,
            floor: floor,
            trade: tradeName,
            title: trimmedTitle,
            description: snagDescription.isEmpty ? nil : snagDescription,
            hasPhoto: hasPhoto
        )
        viewModel.sendMessage(message, channel: "defects")

        // Send photo if attached
        if hasPhoto, let image = photoImage {
            isSendingPhoto = true
            let fileName = SnagMessage.photoFilename(floor: floor, priority: priority)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                do {
                    let processedURL = try ImageUtils.processImage(image, maxDimension: 800)
                    let processedData = try Data(contentsOf: processedURL)
                    try? FileManager.default.removeItem(at: processedURL)
                    viewModel.sendSnagPhoto(jpegData: processedData, fileName: fileName)
                } catch {
                }
                withAnimation { isSendingPhoto = false }
            }
        }

        // Toast + dismiss
        withAnimation { showToast = true }
        let delay: Double = hasPhoto ? 2.0 : 1.2
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            dismiss()
        }
    }
}

#endif
