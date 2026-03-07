//
// SiteDataSyncService.swift
// bitchat
//
// Fetches site_config and equipment_locations from Supabase REST API,
// caches JSON + equipment photos to the Documents directory.
//

import Foundation

final class SiteDataSyncService {
    static let shared = SiteDataSyncService()

    private let baseURL = "https://gwolhiudnwacaqvpgmca.supabase.co/rest/v1"
    private let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd3b2xoaXVkbndhY2FxdnBnbWNhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI0ODMwMzUsImV4cCI6MjA4ODA1OTAzNX0.YYWMzTMVOVK_Yn0rVdZkdnPbq32_PzXM3oeq3wwg9SE"

    private init() {}

    // MARK: - Sync

    func sync() async throws {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        // 1. Fetch site_config
        let configURL = URL(string: "\(baseURL)/site_config?select=*&limit=1")!
        let configData = try await fetch(url: configURL)
        try configData.write(to: Self.siteConfigFileURL, options: .atomic)

        // 2. Fetch equipment_locations
        let equipURL = URL(string: "\(baseURL)/equipment_locations?select=*")!
        let equipData = try await fetch(url: equipURL)
        try equipData.write(to: Self.equipmentFileURL, options: .atomic)

        // 3. Download equipment photos
        let equipment = try decoder.decode([EquipmentLocation].self, from: equipData)
        for item in equipment {
            guard let photoURLString = item.photoUrl,
                  let photoURL = URL(string: photoURLString) else { continue }
            do {
                let (imageData, _) = try await URLSession.shared.data(from: photoURL)
                let photoFile = Self.documentsDirectory.appendingPathComponent("equipment_photo_\(item.id).jpg")
                try imageData.write(to: photoFile, options: .atomic)
            } catch {
                // Skip photo if download fails — non-critical
            }
        }

    }

    // MARK: - Local reads

    static func loadSiteConfig() -> SiteConfig? {
        guard let data = try? Data(contentsOf: siteConfigFileURL) else { return nil }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        // Supabase returns an array even with limit=1
        if let array = try? decoder.decode([SiteConfig].self, from: data) {
            return array.first
        }
        return try? decoder.decode(SiteConfig.self, from: data)
    }

    static func loadEquipmentLocations() -> [EquipmentLocation] {
        guard let data = try? Data(contentsOf: equipmentFileURL) else { return [] }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([EquipmentLocation].self, from: data)) ?? []
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

    private static let documentsDirectory: URL = {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }()

    private static let siteConfigFileURL: URL = {
        documentsDirectory.appendingPathComponent("site_config.json")
    }()

    private static let equipmentFileURL: URL = {
        documentsDirectory.appendingPathComponent("equipment_locations.json")
    }()
}
