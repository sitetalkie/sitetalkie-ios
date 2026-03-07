//
// PinDetailView.swift
// bitchat
//
// Detail view for viewing a site pin's full information and actions.
//

import SwiftUI
import CoreLocation

#if os(iOS)

struct PinDetailView: View {
    let pin: SitePin
    let currentUserName: String
    let onDismiss: () -> Void
    var onDelete: ((SitePin) -> Void)?

    @ObservedObject private var distanceTracker = PinDistanceTracker.shared
    @State private var showDeleteConfirmation = false
    @State private var showFullPhoto = false

    // Design system
    private let backgroundColor = Color(red: 0.055, green: 0.063, blue: 0.071)
    private let cardColor = Color(red: 0.102, green: 0.110, blue: 0.125)
    private let borderColor = Color(red: 0.165, green: 0.173, blue: 0.188)
    private let textPrimary = Color(red: 0.941, green: 0.941, blue: 0.941)
    private let textSecondary = Color(red: 0.541, green: 0.557, blue: 0.588)
    private let textTertiary = Color(red: 0.353, green: 0.369, blue: 0.400)
    private let successGreen = Color(red: 0.204, green: 0.780, blue: 0.349)
    private let dangerRed = Color(red: 0.898, green: 0.282, blue: 0.302)
    private let amber = Color(red: 0.910, green: 0.588, blue: 0.047)

    private var distanceText: String {
        distanceTracker.formattedDistance(for: pin.id).text
    }

    private var floorText: String {
        if pin.floor == 0 { return "Ground" }
        if pin.floor < 0 { return "B\(abs(pin.floor))" }
        return "Floor \(pin.floor)"
    }

    private var isOwnPin: Bool {
        pin.createdBy == currentUserName
    }

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header with dismiss
                    HStack {
                        Spacer()
                        Button(action: onDismiss) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(textSecondary)
                        }
                    }

                    // Pin type badge
                    HStack(spacing: 6) {
                        Image(systemName: pin.type.icon)
                            .font(.system(size: 14, weight: .semibold))
                        Text(pin.type.displayName)
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(pin.type.color)
                    )

                    // Title
                    Text(pin.title)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)

                    // Description
                    if let desc = pin.description, !desc.isEmpty {
                        Text(desc)
                            .font(.system(size: 16))
                            .foregroundColor(textSecondary)
                    }

                    // Photo
                    if let photoData = pin.photoData, let uiImage = UIImage(data: photoData) {
                        Button(action: { showFullPhoto = true }) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }

                    // Resolved badge
                    if pin.isResolved {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(successGreen)
                            Text("Resolved")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(successGreen)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(successGreen.opacity(0.15))
                        )
                    }

                    // Info rows
                    VStack(spacing: 0) {
                        infoRow(icon: "building.2", label: floorText)
                        Divider().background(borderColor)
                        infoRow(icon: "location", label: distanceText)
                        Divider().background(borderColor)
                        infoRow(icon: "person", label: pin.createdBy)
                        Divider().background(borderColor)
                        infoRow(icon: "clock", label: pin.timeAgo)
                        Divider().background(borderColor)
                        infoRow(icon: "timer", label: pin.expiryDescription)
                        Divider().background(borderColor)
                        infoRow(icon: "scope", label: "\(Int(pin.radius))m radius")
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(cardColor)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    // Action buttons
                    VStack(spacing: 10) {
                        // Extend button
                        Button(action: extendPin) {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                Text("Extend 24h")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(amber)
                            )
                        }
                        .buttonStyle(.plain)

                        // Delete button (own pins only)
                        if isOwnPin {
                            Button(action: { showDeleteConfirmation = true }) {
                                HStack {
                                    Image(systemName: "trash.fill")
                                    Text("Delete")
                                }
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(dangerRed)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(16)
            }
        }
        .preferredColorScheme(.dark)
        .alert("Delete Pin", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                deletePin()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this pin?")
        }
        .fullScreenCover(isPresented: $showFullPhoto) {
            if let photoData = pin.photoData, let uiImage = UIImage(data: photoData) {
                ZStack {
                    Color.black.ignoresSafeArea()
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: { showFullPhoto = false }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white.opacity(0.8))
                                    .padding(16)
                            }
                        }
                        Spacer()
                    }
                }
            }
        }
    }

    // MARK: - Info Row

    private func infoRow(icon: String, label: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(textSecondary)
                .frame(width: 24)
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(textPrimary)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    // MARK: - Actions

    private func extendPin() {
        SitePinManager.shared.extendPin(pin)
        onDismiss()
    }

    private func deletePin() {
        if let onDelete = onDelete {
            onDelete(pin)
        } else {
            SitePinManager.shared.removePin(pin)
        }
        onDismiss()
    }
}

#endif
