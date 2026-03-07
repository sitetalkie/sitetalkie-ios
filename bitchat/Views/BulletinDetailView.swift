import SwiftUI
import QuickLook

struct BulletinDetailView: View {
    let bulletin: Bulletin
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = BulletinStore.shared
    @State private var hasAcknowledged: Bool = false
    @State private var previewURL: URL?

    // Design system
    private let backgroundColor = Color(red: 0.055, green: 0.063, blue: 0.071)
    private let cardColor = Color(red: 0.102, green: 0.110, blue: 0.125)
    private let elevatedColor = Color(red: 0.141, green: 0.149, blue: 0.157)
    private let borderColor = Color(red: 0.165, green: 0.173, blue: 0.188)
    private let textPrimary = Color(red: 0.941, green: 0.941, blue: 0.941)
    private let textSecondary = Color(red: 0.541, green: 0.557, blue: 0.588)
    private let textTertiary = Color(red: 0.353, green: 0.369, blue: 0.400)
    private let amber = Color(red: 0.910, green: 0.588, blue: 0.047)
    private let red = Color(red: 0.898, green: 0.282, blue: 0.302)
    private let green = Color(red: 0.204, green: 0.780, blue: 0.349)

    private var priorityColor: Color {
        switch bulletin.priority {
        case "urgent": return red
        case "important": return amber
        default: return textSecondary
        }
    }

    private var priorityLabel: String {
        bulletin.priority.capitalized
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Priority badge
                    Text(priorityLabel)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(priorityColor)
                        )

                    // Title
                    Text(bulletin.title)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(textPrimary)

                    // Full content
                    Text(bulletin.content)
                        .font(.system(size: 14))
                        .foregroundColor(textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    divider

                    // Attachments
                    if let attachments = bulletin.attachments, !attachments.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Attachments")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(textPrimary)

                            ForEach(Array(attachments.enumerated()), id: \.offset) { index, attachment in
                                attachmentRow(attachment, index: index)
                            }
                        }

                        divider
                    }

                    // Metadata
                    HStack(spacing: 8) {
                        Image(systemName: "person")
                            .font(.system(size: 13))
                            .foregroundColor(textSecondary)
                        Text(bulletin.createdBy ?? "Site Manager")
                            .font(.system(size: 14))
                            .foregroundColor(textSecondary)
                    }

                    Text(bulletin.fullDateString)
                        .font(.system(size: 13))
                        .foregroundColor(textTertiary)

                    divider

                    // Acknowledge section
                    if bulletin.requiresAck {
                        acknowledgeSection
                    }
                }
                .padding(16)
            }
            .background(backgroundColor.ignoresSafeArea())
            .preferredColorScheme(.dark)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(textSecondary)
                    }
                }
            }
            .quickLookPreview($previewURL)
        }
        .onAppear {
            hasAcknowledged = bulletin.isAcknowledged
            store.markAsRead(bulletin.id)
        }
    }

    // MARK: - Subviews

    private var divider: some View {
        Rectangle()
            .fill(borderColor)
            .frame(height: 1)
    }

    @ViewBuilder
    private func attachmentRow(_ attachment: BulletinAttachment, index: Int) -> some View {
        let isImage = ["jpg", "jpeg", "png", "gif", "heic"].contains(
            (attachment.name as NSString).pathExtension.lowercased()
        )

        if isImage {
            imageAttachment(attachment, index: index)
        } else {
            documentAttachment(attachment, index: index)
        }
    }

    @ViewBuilder
    private func imageAttachment(_ attachment: BulletinAttachment, index: Int) -> some View {
        let localURL = BulletinSyncService.cachedAttachmentURL(
            bulletinId: bulletin.id, index: index, name: attachment.name
        )

        if let localURL = localURL, let uiImage = UIImage(contentsOfFile: localURL.path) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onTapGesture {
                    previewURL = localURL
                }
        } else if let remoteURL = URL(string: attachment.url) {
            AsyncImage(url: remoteURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                case .failure:
                    attachmentPlaceholder(attachment)
                default:
                    ProgressView()
                        .frame(height: 100)
                }
            }
        }
    }

    private func documentAttachment(_ attachment: BulletinAttachment, index: Int) -> some View {
        let localURL = BulletinSyncService.cachedAttachmentURL(
            bulletinId: bulletin.id, index: index, name: attachment.name
        )

        return Button(action: {
            if let localURL = localURL {
                previewURL = localURL
            } else if let remoteURL = URL(string: attachment.url) {
                UIApplication.shared.open(remoteURL)
            }
        }) {
            HStack(spacing: 10) {
                Image(systemName: "doc.fill")
                    .font(.system(size: 20))
                    .foregroundColor(textSecondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(attachment.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(textPrimary)
                        .lineLimit(1)
                    Text(attachment.type.uppercased())
                        .font(.system(size: 11))
                        .foregroundColor(textTertiary)
                }
                Spacer()
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 16))
                    .foregroundColor(textSecondary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(cardColor)
            )
        }
        .buttonStyle(.plain)
    }

    private func attachmentPlaceholder(_ attachment: BulletinAttachment) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "photo")
                .foregroundColor(textTertiary)
            Text(attachment.name)
                .font(.system(size: 13))
                .foregroundColor(textSecondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 8).fill(cardColor))
    }

    @ViewBuilder
    private var acknowledgeSection: some View {
        if hasAcknowledged || bulletin.isAcknowledged {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(green)
                Text("Acknowledged")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(green)
                if let ackDate = bulletin.acknowledgedAt {
                    Spacer()
                    Text(ackTimeAgo(ackDate))
                        .font(.system(size: 13))
                        .foregroundColor(textSecondary)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(green.opacity(0.1))
            )
        } else {
            Button(action: {
                performAcknowledge()
            }) {
                Text("Acknowledge this bulletin")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(amber)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Actions

    private func performAcknowledge() {
        // 1. Mark locally
        store.markAsAcknowledged(bulletin.id)
        withAnimation { hasAcknowledged = true }

        // 2. Send BLE ack message via notification (ChatViewModel picks it up)
        NotificationCenter.default.post(
            name: .bulletinAcknowledge,
            object: nil,
            userInfo: ["bulletinId": bulletin.id]
        )

        // 3. POST to Supabase in background
        let senderId = UserDefaults.standard.string(forKey: "sitetalkie.deviceId") ?? UUID().uuidString
        let displayName = UserDefaults.standard.string(forKey: "sitetalkie.nickname") ?? "Worker"
        Task {
            await BulletinSyncService.shared.postAcknowledgment(
                bulletinId: bulletin.id,
                senderId: senderId,
                displayName: displayName
            )
        }
    }

    private func ackTimeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 { return "just now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        return "\(Int(interval / 86400))d ago"
    }
}

// MARK: - Notification name

extension Notification.Name {
    static let bulletinAcknowledge = Notification.Name("sitetalkie.bulletinAcknowledge")
    static let bulletinReceived = Notification.Name("sitetalkie.bulletinReceived")
}
