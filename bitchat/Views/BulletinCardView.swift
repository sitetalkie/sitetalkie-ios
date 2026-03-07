import SwiftUI

struct BulletinCardView: View {
    let bulletin: Bulletin

    // Design system
    private let cardColor = Color(red: 0.102, green: 0.110, blue: 0.125)
    private let elevatedColor = Color(red: 0.141, green: 0.149, blue: 0.157)
    private let textPrimary = Color(red: 0.941, green: 0.941, blue: 0.941)
    private let textSecondary = Color(red: 0.541, green: 0.557, blue: 0.588)
    private let textTertiary = Color(red: 0.353, green: 0.369, blue: 0.400)
    private let amber = Color(red: 0.910, green: 0.588, blue: 0.047)
    private let red = Color(red: 0.898, green: 0.282, blue: 0.302)
    private let green = Color(red: 0.204, green: 0.780, blue: 0.349)

    @State private var urgentOpacity: Double = 1.0

    private var priorityColor: Color {
        switch bulletin.priority {
        case "urgent": return red
        case "important": return amber
        default: return textSecondary
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Priority bar
            RoundedRectangle(cornerRadius: 1.5)
                .fill(priorityColor)
                .frame(width: 3)
                .opacity(bulletin.priority == "urgent" ? urgentOpacity : 1.0)

            // Content
            VStack(alignment: .leading, spacing: 8) {
                // Title row
                HStack(alignment: .top) {
                    Text(bulletin.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(textPrimary)
                        .lineLimit(2)

                    Spacer()

                    if !bulletin.isRead {
                        Circle()
                            .fill(amber)
                            .frame(width: 6, height: 6)
                    }
                }

                // Content preview
                if !bulletin.content.isEmpty {
                    Text(bulletin.content)
                        .font(.system(size: 12))
                        .foregroundColor(textSecondary)
                        .lineLimit(3)
                }

                // Metadata row
                HStack(spacing: 12) {
                    Text(bulletin.timeAgo)
                        .font(.system(size: 11))
                        .foregroundColor(textTertiary)

                    Text("From: \(bulletin.createdBy ?? "Site Manager")")
                        .font(.system(size: 11))
                        .foregroundColor(textTertiary)
                }

                // Attachment chips
                if let attachments = bulletin.attachments, !attachments.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(attachments, id: \.name) { attachment in
                                HStack(spacing: 4) {
                                    Image(systemName: "paperclip")
                                        .font(.system(size: 10))
                                        .foregroundColor(textSecondary)
                                    Text(attachment.name)
                                        .font(.system(size: 11))
                                        .foregroundColor(textSecondary)
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(elevatedColor)
                                )
                            }
                        }
                    }
                }

                // Acknowledgment section
                if bulletin.requiresAck {
                    if bulletin.isAcknowledged {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(green)
                            Text("Acknowledged")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(green)
                            if let ackDate = bulletin.acknowledgedAt {
                                Text(ackTimeAgo(ackDate))
                                    .font(.system(size: 11))
                                    .foregroundColor(textSecondary)
                            }
                        }
                        .padding(.top, 4)
                    } else {
                        Button(action: {
                            BulletinStore.shared.markAsAcknowledged(bulletin.id)
                        }) {
                            Text("Acknowledge")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(amber)
                                )
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                    }
                }
            }
            .padding(12)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(cardColor)
        )
        .onAppear {
            if bulletin.priority == "urgent" {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    urgentOpacity = 0.7
                }
            }
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
