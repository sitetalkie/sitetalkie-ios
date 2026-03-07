import Foundation

struct Bulletin: Codable, Identifiable {
    let id: Int
    let title: String
    let content: String
    let priority: String
    let requiresAck: Bool
    let attachments: [BulletinAttachment]?
    let scheduledAt: Date?
    let publishedAt: Date?
    let status: String
    let createdBy: String?
    let createdAt: Date

    var isRead: Bool
    var isAcknowledged: Bool
    var acknowledgedAt: Date?

    init(
        id: Int,
        title: String,
        content: String,
        priority: String = "normal",
        requiresAck: Bool = false,
        attachments: [BulletinAttachment]? = nil,
        scheduledAt: Date? = nil,
        publishedAt: Date? = nil,
        status: String = "published",
        createdBy: String? = nil,
        createdAt: Date = Date(),
        isRead: Bool = false,
        isAcknowledged: Bool = false,
        acknowledgedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.priority = priority
        self.requiresAck = requiresAck
        self.attachments = attachments
        self.scheduledAt = scheduledAt
        self.publishedAt = publishedAt
        self.status = status
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.isRead = isRead
        self.isAcknowledged = isAcknowledged
        self.acknowledgedAt = acknowledgedAt
    }

    enum CodingKeys: String, CodingKey {
        case id, title, content, priority
        case requiresAck, attachments, scheduledAt, publishedAt
        case status, createdBy, createdAt
        case isRead, isAcknowledged, acknowledgedAt
    }

    var timeAgo: String {
        let interval = Date().timeIntervalSince(createdAt)
        if interval < 60 { return "just now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        let days = Int(interval / 86400)
        if days == 1 { return "Yesterday" }
        return "\(days)d ago"
    }

    var fullDateString: String {
        let f = DateFormatter()
        f.dateFormat = "d MMMM yyyy, HH:mm"
        return f.string(from: createdAt)
    }
}

struct BulletinAttachment: Codable {
    let url: String
    let name: String
    let type: String
}
