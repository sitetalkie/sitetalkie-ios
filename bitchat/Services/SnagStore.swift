//
// SnagStore.swift
// bitchat
//
// Singleton store for snag persistence. Same pattern as BulletinStore.
// Persists to Documents/snags.json.
//

import Foundation

#if os(iOS)

final class SnagStore: ObservableObject {
    static let shared = SnagStore()

    @Published var snags: [Snag] = []
    @Published var viewedSnagIds: Set<String> = []

    private static let viewedSnagIdsKey = "sitetalkie.viewedSnagIds"

    private static let documentsDirectory: URL = {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }()

    private static let fileURL: URL = {
        documentsDirectory.appendingPathComponent("snags.json")
    }()

    private init() {
        load()
        loadViewedIds()
    }

    // MARK: - CRUD

    func addSnag(_ snag: Snag) {
        guard !snags.contains(where: { $0.id == snag.id }) else { return }
        snags.insert(snag, at: 0)
        save()
    }

    /// Ingest a snag from an incoming mesh [SNAG:...] message.
    func addFromMesh(_ parsed: SnagMessage, sender: String) {
        let id = parsed.id ?? UUID().uuidString
        guard !snags.contains(where: { $0.id == id }) else { return }
        let snag = Snag(
            id: id,
            title: parsed.title,
            description: parsed.detail.isEmpty ? nil : parsed.detail,
            priority: parsed.priority,
            trade: parsed.trade,
            floor: parsed.floor,
            createdBy: sender,
            status: .open,
            hasPhoto: parsed.hasPhoto
        )
        snags.insert(snag, at: 0)
        save()
    }

    func updateStatus(_ id: String, status: SnagStatus) {
        guard let idx = snags.firstIndex(where: { $0.id == id }) else { return }
        snags[idx].status = status
        save()
    }

    func delete(_ id: String) {
        snags.removeAll { $0.id == id }
        viewedSnagIds.remove(id)
        save()
        saveViewedIds()
    }

    func markSnagsViewed(_ ids: [String]) {
        let newIds = ids.filter { !viewedSnagIds.contains($0) }
        guard !newIds.isEmpty else { return }
        viewedSnagIds.formUnion(newIds)
        saveViewedIds()
    }

    // MARK: - Persistence

    func save() {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(snags) else { return }
        try? data.write(to: Self.fileURL, options: .atomic)
    }

    func load() {
        guard let data = try? Data(contentsOf: Self.fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        guard let loaded = try? decoder.decode([Snag].self, from: data) else { return }
        snags = loaded.sorted { $0.createdAt > $1.createdAt }
    }

    private func loadViewedIds() {
        let arr = UserDefaults.standard.stringArray(forKey: Self.viewedSnagIdsKey) ?? []
        viewedSnagIds = Set(arr)
    }

    private func saveViewedIds() {
        UserDefaults.standard.set(Array(viewedSnagIds), forKey: Self.viewedSnagIdsKey)
    }
}

#endif
