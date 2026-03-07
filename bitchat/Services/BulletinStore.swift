import Foundation

final class BulletinStore: ObservableObject {
    static let shared = BulletinStore()

    @Published var bulletins: [Bulletin] = []
    @Published var unreadCount: Int = 0

    private let ackedKey = "sitetalkie.acknowledgedBulletins"

    private static let documentsDirectory: URL = {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }()

    private static let fileURL: URL = {
        documentsDirectory.appendingPathComponent("bulletins.json")
    }()

    private init() {
        load()
    }

    // MARK: - Mesh ingestion

    func addFromMesh(_ message: BulletinMessage) {
        // Skip if already exists
        guard !bulletins.contains(where: { $0.id == message.id }) else { return }

        let ackedIDs = loadAcknowledgedIDs()
        let alreadyAcked = ackedIDs.contains(message.id)

        let bulletin = Bulletin(
            id: message.id,
            title: message.title,
            content: message.content,
            priority: "normal",
            requiresAck: message.requiresAck,
            status: "published",
            createdAt: Date(),
            isRead: false,
            isAcknowledged: alreadyAcked,
            acknowledgedAt: alreadyAcked ? Date() : nil
        )

        bulletins.insert(bulletin, at: 0)
        recalculateUnread()
        save()
    }

    // MARK: - State mutations

    func markAsRead(_ id: Int) {
        guard let index = bulletins.firstIndex(where: { $0.id == id }) else { return }
        guard !bulletins[index].isRead else { return }
        bulletins[index].isRead = true
        recalculateUnread()
        save()
    }

    func markAsAcknowledged(_ id: Int) {
        guard let index = bulletins.firstIndex(where: { $0.id == id }) else { return }
        guard !bulletins[index].isAcknowledged else { return }
        bulletins[index].isAcknowledged = true
        bulletins[index].acknowledgedAt = Date()
        saveAcknowledgedID(id)
        save()
    }

    // MARK: - Supabase merge

    func mergeFromSupabase(_ fetched: [Bulletin]) {
        let ackedIDs = loadAcknowledgedIDs()

        for remote in fetched {
            if let index = bulletins.firstIndex(where: { $0.id == remote.id }) {
                // Update metadata but preserve local read/ack state
                let local = bulletins[index]
                bulletins[index] = Bulletin(
                    id: remote.id,
                    title: remote.title,
                    content: remote.content,
                    priority: remote.priority,
                    requiresAck: remote.requiresAck,
                    attachments: remote.attachments,
                    scheduledAt: remote.scheduledAt,
                    publishedAt: remote.publishedAt,
                    status: remote.status,
                    createdBy: remote.createdBy,
                    createdAt: remote.createdAt,
                    isRead: local.isRead,
                    isAcknowledged: local.isAcknowledged || ackedIDs.contains(remote.id),
                    acknowledgedAt: local.acknowledgedAt
                )
            } else {
                // New from Supabase
                var bulletin = remote
                bulletin.isRead = false
                bulletin.isAcknowledged = ackedIDs.contains(remote.id)
                bulletin.acknowledgedAt = bulletin.isAcknowledged ? Date() : nil
                bulletins.append(bulletin)
            }
        }

        // Sort newest first
        bulletins.sort { $0.createdAt > $1.createdAt }
        recalculateUnread()
        save()
    }

    // MARK: - Persistence

    func save() {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(bulletins) else { return }
        try? data.write(to: Self.fileURL, options: .atomic)
    }

    func load() {
        guard let data = try? Data(contentsOf: Self.fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        guard let loaded = try? decoder.decode([Bulletin].self, from: data) else { return }
        bulletins = loaded.sorted { $0.createdAt > $1.createdAt }
        recalculateUnread()
    }

    // MARK: - Acknowledged IDs (UserDefaults)

    private func loadAcknowledgedIDs() -> Set<Int> {
        let array = UserDefaults.standard.array(forKey: ackedKey) as? [Int] ?? []
        return Set(array)
    }

    private func saveAcknowledgedID(_ id: Int) {
        var ids = loadAcknowledgedIDs()
        ids.insert(id)
        UserDefaults.standard.set(Array(ids), forKey: ackedKey)
    }

    // MARK: - Helpers

    private func recalculateUnread() {
        unreadCount = bulletins.filter { !$0.isRead }.count
    }
}
