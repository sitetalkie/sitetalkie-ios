//
// SitePin.swift
// bitchat
//
// Location pin data model for marking hazards and notes on site.
// Legacy .snag and .safeZone cases kept for backward-compatible decoding of existing stored pins.
//

import SwiftUI

#if os(iOS)

// MARK: - Pin Type

enum PinType: String, Codable {
    case hazard
    case note
    // Legacy cases — kept for backward-compatible decoding only. Do not create new pins with these types.
    case snag
    case safeZone

    var displayName: String {
        switch self {
        case .hazard: return "Hazard"
        case .note: return "Note"
        case .snag: return "Snag"
        case .safeZone: return "Safe Zone"
        }
    }

    var pluralName: String {
        switch self {
        case .hazard: return "HAZARDS"
        case .note: return "NOTES"
        case .snag: return "SNAGS"
        case .safeZone: return "SAFE ZONES"
        }
    }

    var icon: String {
        switch self {
        case .hazard: return "exclamationmark.triangle.fill"
        case .note: return "doc.text.fill"
        case .snag: return "wrench.fill"
        case .safeZone: return "checkmark.shield.fill"
        }
    }

    var color: Color {
        switch self {
        case .hazard: return Color(red: 0.898, green: 0.282, blue: 0.302)   // #E5484D
        case .note: return Color(red: 0.231, green: 0.510, blue: 0.965)     // #3B82F6
        case .snag: return Color(red: 0.910, green: 0.588, blue: 0.047)     // #E8960C
        case .safeZone: return Color(red: 0.204, green: 0.780, blue: 0.349) // #34C759
        }
    }

    /// Priority for geofence slot allocation (lower = higher priority)
    var geofencePriority: Int {
        switch self {
        case .hazard: return 0
        case .note: return 2
        case .snag: return 1
        case .safeZone: return 3
        }
    }

    /// Whether this pin type is currently active (can be created by users)
    var isActive: Bool {
        switch self {
        case .hazard, .note: return true
        case .snag, .safeZone: return false
        }
    }
}

// MARK: - Pin Precision

enum PinPrecision: String, Codable, CaseIterable {
    case precise = "20"
    case roomWide = "50"
    case buildingWide = "200"

    var radiusMetres: Double {
        Double(self.rawValue) ?? 20
    }

    var displayName: String {
        switch self {
        case .precise: return "Precise (20m)"
        case .roomWide: return "Room (50m)"
        case .buildingWide: return "Building (200m)"
        }
    }
}

// MARK: - Site Pin

struct SitePin: Codable, Identifiable {
    let id: String
    let type: PinType
    let title: String
    let description: String?
    let latitude: Double
    let longitude: Double
    let floor: Int
    let createdBy: String
    let createdAt: Date
    var expiresAt: Date?
    var isResolved: Bool
    let photoData: Data?
    let radius: Double
    let precision: PinPrecision
    let channels: [String] // e.g. ["site", "defects"] or ["all"]

    private enum CodingKeys: String, CodingKey {
        case id, type, title, description, latitude, longitude, floor
        case createdBy, createdAt, expiresAt, isResolved, photoData
        case radius, precision, channels, channel, priority, assignedTrade
    }

    init(
        id: String = UUID().uuidString,
        type: PinType,
        title: String,
        description: String? = nil,
        latitude: Double,
        longitude: Double,
        floor: Int,
        createdBy: String,
        createdAt: Date = Date(),
        expiresAt: Date? = nil,
        isResolved: Bool = false,
        photoData: Data? = nil,
        radius: Double = 20,
        precision: PinPrecision = .precise,
        channels: [String] = ["site"]
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.description = description
        self.latitude = latitude
        self.longitude = longitude
        self.floor = floor
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.isResolved = isResolved
        self.photoData = photoData
        self.radius = radius
        self.precision = precision
        self.channels = channels
    }

    // Custom decoder for backward compatibility — existing pins may have old `channel: String`,
    // new `channels: [String]`, or legacy snag fields (priority, assignedTrade).
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        type = try container.decode(PinType.self, forKey: .type)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        floor = try container.decode(Int.self, forKey: .floor)
        createdBy = try container.decode(String.self, forKey: .createdBy)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        expiresAt = try container.decodeIfPresent(Date.self, forKey: .expiresAt)
        isResolved = try container.decode(Bool.self, forKey: .isResolved)
        photoData = try container.decodeIfPresent(Data.self, forKey: .photoData)
        radius = try container.decode(Double.self, forKey: .radius)
        precision = try container.decode(PinPrecision.self, forKey: .precision)
        // Try new `channels` array first, fall back to old `channel` string
        if let arr = try container.decodeIfPresent([String].self, forKey: .channels) {
            channels = arr
        } else if let single = try container.decodeIfPresent(String.self, forKey: .channel) {
            channels = [single]
        } else {
            channels = ["site"]
        }
        // Legacy snag fields — silently ignore (no longer stored on SitePin)
        _ = try? container.decodeIfPresent(String.self, forKey: .priority)
        _ = try? container.decodeIfPresent(String.self, forKey: .assignedTrade)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(floor, forKey: .floor)
        try container.encode(createdBy, forKey: .createdBy)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(expiresAt, forKey: .expiresAt)
        try container.encode(isResolved, forKey: .isResolved)
        try container.encodeIfPresent(photoData, forKey: .photoData)
        try container.encode(radius, forKey: .radius)
        try container.encode(precision, forKey: .precision)
        try container.encode(channels, forKey: .channels)
        // Do NOT encode old `channel`, `priority`, or `assignedTrade` keys
    }

    /// Time-ago string for display
    var timeAgo: String {
        let interval = Date().timeIntervalSince(createdAt)
        if interval < 60 { return "just now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        return "\(Int(interval / 86400))d ago"
    }

    /// Expiry description for display
    var expiryDescription: String {
        guard let exp = expiresAt else { return "No expiry" }
        let remaining = exp.timeIntervalSince(Date())
        if remaining <= 0 { return "Expired" }
        if remaining < 3600 { return "In \(Int(remaining / 60))m" }
        if remaining < 86400 { return "In \(Int(remaining / 3600))h" }
        return "In \(Int(remaining / 86400))d"
    }
}

#endif
