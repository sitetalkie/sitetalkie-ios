//
// SiteDataStore.swift
// bitchat
//
// Observable store backed by locally cached Supabase JSON files.
//

import Foundation

final class SiteDataStore: ObservableObject {
    @Published var siteConfig: SiteConfig? = SiteDataSyncService.loadSiteConfig()
    @Published var equipment: [EquipmentLocation] = SiteDataSyncService.loadEquipmentLocations()

    func refresh() async {
        try? await SiteDataSyncService.shared.sync()
        siteConfig = SiteDataSyncService.loadSiteConfig()
        equipment = SiteDataSyncService.loadEquipmentLocations()
    }
}
