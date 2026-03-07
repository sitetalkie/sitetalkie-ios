import Foundation

final class BulletinSyncService {
    static let shared = BulletinSyncService()

    private let baseURL = "https://gwolhiudnwacaqvpgmca.supabase.co/rest/v1"
    private let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd3b2xoaXVkbndhY2FxdnBnbWNhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI0ODMwMzUsImV4cCI6MjA4ODA1OTAzNX0.YYWMzTMVOVK_Yn0rVdZkdnPbq32_PzXM3oeq3wwg9SE"

    private var refreshTimer: Timer?

    private static let documentsDirectory: URL = {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }()

    private init() {}

    // MARK: - Sync bulletins

    func sync() async throws {
        let urlString = "\(baseURL)/bulletins?select=*&status=in.(published,broadcast)&order=created_at.desc"
        guard let url = URL(string: urlString) else { return }

        let data = try await fetch(url: url)

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        let fetched = try decoder.decode([Bulletin].self, from: data)

        await MainActor.run {
            BulletinStore.shared.mergeFromSupabase(fetched)
        }

        // Cache attachments in background
        for bulletin in fetched {
            guard let attachments = bulletin.attachments else { continue }
            for (index, attachment) in attachments.enumerated() {
                await cacheAttachment(attachment, bulletinId: bulletin.id, index: index)
            }
        }
    }

    // MARK: - Post acknowledgment

    func postAcknowledgment(bulletinId: Int, senderId: String, displayName: String) async {
        guard let url = URL(string: "\(baseURL)/bulletin_acks") else { return }

        let formatter = ISO8601DateFormatter()
        let body: [String: Any] = [
            "bulletin_id": bulletinId,
            "sender_id": senderId,
            "display_name": displayName,
            "acked_at": formatter.string(from: Date())
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 15

        _ = try? await URLSession.shared.data(for: request)
    }

    // MARK: - Background refresh timer

    func startBackgroundRefresh() {
        guard refreshTimer == nil else { return }
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task {
                try? await self?.sync()
            }
        }
    }

    func stopBackgroundRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    // MARK: - Attachment caching

    private func cacheAttachment(_ attachment: BulletinAttachment, bulletinId: Int, index: Int) async {
        guard let remoteURL = URL(string: attachment.url) else { return }

        let ext = (attachment.name as NSString).pathExtension
        let filename = "bulletin_attachment_\(bulletinId)_\(index).\(ext.isEmpty ? "jpg" : ext)"
        let localURL = Self.documentsDirectory.appendingPathComponent(filename)

        // Skip if already cached
        guard !FileManager.default.fileExists(atPath: localURL.path) else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: remoteURL)
            try data.write(to: localURL, options: .atomic)
        } catch {
            // Non-critical — skip
        }
    }

    /// Get the local cached path for an attachment, or nil if not cached.
    static func cachedAttachmentURL(bulletinId: Int, index: Int, name: String) -> URL? {
        let ext = (name as NSString).pathExtension
        let filename = "bulletin_attachment_\(bulletinId)_\(index).\(ext.isEmpty ? "jpg" : ext)"
        let localURL = documentsDirectory.appendingPathComponent(filename)
        return FileManager.default.fileExists(atPath: localURL.path) ? localURL : nil
    }

    // MARK: - Private

    private func fetch(url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15
        let (data, _) = try await URLSession.shared.data(for: request)
        return data
    }
}
