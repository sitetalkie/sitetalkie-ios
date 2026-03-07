//
// EquipmentLocation.swift
// bitchat
//

import Foundation

struct EquipmentLocation: Codable, Identifiable {
    let id: Int
    let equipmentType: String
    let label: String
    let description: String?
    let floor: String?
    let nearestNodeId: String?
    let photoUrl: String?
    let updatedAt: Date
}
