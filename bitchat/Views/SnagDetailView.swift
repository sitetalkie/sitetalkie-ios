//
// SnagDetailView.swift
// bitchat
//
// Detail view for a snag — shows full details and action buttons
// for status workflow (Start Work, Resolve, Delete).
//

import SwiftUI

#if os(iOS)

struct SnagDetailView: View {
    let snag: Snag
    @EnvironmentObject var viewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss

    @ObservedObject private var snagStore = SnagStore.shared
    @State private var showDeleteConfirmation = false
    @State private var showResolveConfirmation = false
    @State private var showFullPhoto = false

    // Design system
    private let backgroundColor = Color(red: 0.055, green: 0.063, blue: 0.071) // #0E1012
    private let cardColor = Color(red: 0.102, green: 0.110, blue: 0.125)       // #1A1C20
    private let borderColor = Color(red: 0.165, green: 0.173, blue: 0.188)     // #2A2C30
    private let textPrimary = Color(red: 0.941, green: 0.941, blue: 0.941)     // #F0F0F0
    private let textSecondary = Color(red: 0.541, green: 0.557, blue: 0.588)   // #8A8E96
    private let textTertiary = Color(red: 0.353, green: 0.369, blue: 0.400)    // #5A5E66
    private let amber = Color(red: 0.910, green: 0.588, blue: 0.047)           // #E8960C
    private let blue = Color(red: 0.231, green: 0.510, blue: 0.965)            // #3B82F6
    private let successGreen = Color(red: 0.204, green: 0.780, blue: 0.349)    // #34C759
    private let red = Color(red: 0.898, green: 0.282, blue: 0.302)             // #E5484D

    // Read live status from store
    private var liveSnag: Snag {
        snagStore.snags.first(where: { $0.id == snag.id }) ?? snag
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Badges row
                    HStack(spacing: 8) {
                        // Priority badge
                        Text(liveSnag.priority.label.uppercased())
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(liveSnag.priority.color)
                            )

                        // Status badge
                        Text(liveSnag.status.displayName)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(liveSnag.status.color)
                            )

                        Spacer()
                    }

                    // Title
                    Text(liveSnag.title)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(textPrimary)

                    // Description
                    if let desc = liveSnag.description, !desc.isEmpty {
                        Text(desc)
                            .font(.system(size: 14))
                            .foregroundColor(textSecondary)
                    }

                    // Metadata
                    VStack(alignment: .leading, spacing: 10) {
                        if let trade = liveSnag.trade {
                            metadataRow(icon: "wrench", label: trade)
                        }

                        metadataRow(icon: "building.2", label: liveSnag.floorLabel)

                        metadataRow(icon: "person", label: "\(liveSnag.createdBy) \u{00B7} \(liveSnag.timeAgo)")
                    }

                    // Photo
                    if let photoData = liveSnag.photoData, let uiImage = UIImage(data: photoData) {
                        Button(action: { showFullPhoto = true }) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    } else if liveSnag.hasPhoto {
                        HStack(spacing: 6) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 14))
                            Text("Photo attached (sent over mesh)")
                                .font(.system(size: 13))
                        }
                        .foregroundColor(textTertiary)
                    }

                    // Divider
                    Rectangle()
                        .fill(borderColor)
                        .frame(height: 1)

                    // Action buttons
                    actionButtons
                }
                .padding(16)
            }
            .background(backgroundColor.ignoresSafeArea())
            .navigationTitle("Snag Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundColor(textSecondary)
                }
            }
        }
        .preferredColorScheme(.dark)
        .alert("Delete Snag", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) { deleteSnag() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This snag will be removed for all users.")
        }
        .alert("Mark Resolved", isPresented: $showResolveConfirmation) {
            Button("Resolve") { resolveSnag() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Mark this snag as resolved?")
        }
        .fullScreenCover(isPresented: $showFullPhoto) {
            if let photoData = liveSnag.photoData, let uiImage = UIImage(data: photoData) {
                ZStack {
                    Color.black.ignoresSafeArea()
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                }
                .onTapGesture { showFullPhoto = false }
            }
        }
    }

    // MARK: - Metadata Row

    private func metadataRow(icon: String, label: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(textTertiary)
                .frame(width: 20)
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(textSecondary)
        }
    }

    // MARK: - Action Buttons

    @ViewBuilder
    private var actionButtons: some View {
        VStack(spacing: 10) {
            // Start Work — only if status is .open
            if liveSnag.status == .open {
                Button(action: startWork) {
                    HStack {
                        Image(systemName: "hammer.fill")
                        Text("Start Work")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(blue)
                    )
                }
                .buttonStyle(.plain)
            }

            // Mark Resolved — if not already resolved
            if liveSnag.status != .resolved {
                Button(action: { showResolveConfirmation = true }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Mark Resolved")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(successGreen)
                    )
                }
                .buttonStyle(.plain)
            }

            // Delete — only if created by current user
            if liveSnag.createdBy == viewModel.nickname {
                Button(action: { showDeleteConfirmation = true }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(red)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Actions

    private func startWork() {
        viewModel.broadcastSnagProgress(snag.id)
    }

    private func resolveSnag() {
        viewModel.resolveAndBroadcastSnag(snag.id)
        dismiss()
    }

    private func deleteSnag() {
        viewModel.deleteAndBroadcastSnag(snag.id)
        dismiss()
    }
}

#endif
