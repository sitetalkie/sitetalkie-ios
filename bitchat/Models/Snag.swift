//
// Snag.swift
// bitchat
//
// Snag data model for tracking defects on site.
// Separate from SitePin — snags have priority, trade assignment, and status workflow.
//

import SwiftUI

#if os(iOS)

// MARK: - Snag Priority

enum SnagPriority: String, Codable, CaseIterable {
    case high = "HIGH"
    case medium = "MED"
    case low = "LOW"

    var color: Color {
        switch self {
        case .high: return Color(red: 0.898, green: 0.282, blue: 0.302)    // #E5484D
        case .medium: return Color(red: 0.910, green: 0.588, blue: 0.047)  // #E8960C
        case .low: return Color(red: 0.443, green: 0.443, blue: 0.478)     // #71717A
        }
    }

    var label: String {
        switch self {
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        }
    }

    var icon: String {
        switch self {
        case .high: return "exclamationmark.circle.fill"
        case .medium: return "minus.circle.fill"
        case .low: return "arrow.down.circle.fill"
        }
    }
}

// MARK: - Snag Status

enum SnagStatus: String, Codable, CaseIterable {
    case open
    case inProgress
    case resolved

    var displayName: String {
        switch self {
        case .open: return "Open"
        case .inProgress: return "In Progress"
        case .resolved: return "Resolved"
        }
    }

    var color: Color {
        switch self {
        case .open: return Color(red: 0.910, green: 0.588, blue: 0.047)      // #E8960C
        case .inProgress: return Color(red: 0.231, green: 0.510, blue: 0.965) // #3B82F6
        case .resolved: return Color(red: 0.204, green: 0.780, blue: 0.349)   // #34C759
        }
    }
}

// MARK: - Snag

struct Snag: Codable, Identifiable {
    let id: String
    let title: String
    let description: String?
    let priority: SnagPriority
    let trade: String?
    let floor: Int
    let createdBy: String
    let createdAt: Date
    var status: SnagStatus
    let hasPhoto: Bool
    let photoData: Data?

    init(
        id: String = UUID().uuidString,
        title: String,
        description: String? = nil,
        priority: SnagPriority = .medium,
        trade: String? = nil,
        floor: Int = 0,
        createdBy: String,
        createdAt: Date = Date(),
        status: SnagStatus = .open,
        hasPhoto: Bool = false,
        photoData: Data? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.priority = priority
        self.trade = trade
        self.floor = floor
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.status = status
        self.hasPhoto = hasPhoto
        self.photoData = photoData
    }

    var timeAgo: String {
        let interval = Date().timeIntervalSince(createdAt)
        if interval < 60 { return "just now" }
        if interval < 3600 { return "\(Int(interval / 60))m ago" }
        if interval < 86400 { return "\(Int(interval / 3600))h ago" }
        return "\(Int(interval / 86400))d ago"
    }

    var floorLabel: String {
        if floor == 0 { return "Ground" }
        if floor < 0 { return "Basement \(abs(floor))" }
        return "Floor \(floor)"
    }
}

#endif
