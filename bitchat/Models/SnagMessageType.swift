//
// SnagMessageType.swift
// bitchat
//
// Parser for [SNAG:...] mesh broadcast messages.
// New format: [SNAG:{uuid}:{priority}:{floor}:{trade}:{PHOTO}] {title} | {description}
// Old format: [SNAG:{priority}:{floor}:{trade}] {title} | {description}
// Example:    [SNAG:A1B2C3D4-E5F6-7890-ABCD-EF1234567890:HIGH:F3:MECHANICAL:PHOTO] Leaking valve | Found in plant room B
//

import SwiftUI

#if os(iOS)

struct SnagMessage {
    let id: String?
    let priority: SnagPriority
    let floorLabel: String?
    let floor: Int
    let trade: String?
    let title: String
    let detail: String
    let hasPhoto: Bool

    /// Parse a [SNAG:...] message from content string.
    /// Handles both old format (no UUID) and new format (UUID as first field).
    /// Old: [SNAG:HIGH:F3:TRADE] or [SNAG:HIGH:F3:TRADE:PHOTO]
    /// New: [SNAG:uuid:HIGH:F3:TRADE] or [SNAG:uuid:HIGH:F3:TRADE:PHOTO]
    static func parse(from content: String) -> SnagMessage? {
        guard content.hasPrefix("[SNAG:") else { return nil }
        guard let closeBracket = content.firstIndex(of: "]") else { return nil }

        let inside = String(content[content.index(content.startIndex, offsetBy: 6)..<closeBracket])
        let afterBracket = String(content[content.index(after: closeBracket)...]).trimmingCharacters(in: .whitespacesAndNewlines)

        let parts = inside.split(separator: ":", maxSplits: 5).map(String.init)
        guard !parts.isEmpty else { return nil }

        // Detect format: if first field contains a hyphen, it's a UUID (new format)
        let id: String?
        let priorityIndex: Int

        if parts[0].contains("-") {
            // New format: [SNAG:uuid:PRIORITY:FLOOR:TRADE:PHOTO]
            id = parts[0]
            priorityIndex = 1
        } else {
            // Old format: [SNAG:PRIORITY:FLOOR:TRADE:PHOTO]
            id = nil
            priorityIndex = 0
        }

        guard parts.count > priorityIndex,
              let priority = SnagPriority(rawValue: parts[priorityIndex]) else { return nil }

        let floorIndex = priorityIndex + 1
        let floorLabel: String? = parts.count > floorIndex ? readableFloor(from: parts[floorIndex]) : nil
        let floorInt: Int = parts.count > floorIndex ? parseFloorInt(from: parts[floorIndex]) : 0

        let tradeIndex = priorityIndex + 2
        let trade: String? = parts.count > tradeIndex && parts[tradeIndex] != "PHOTO" ? parts[tradeIndex] : nil

        let hasPhoto = parts.contains("PHOTO")

        // Parse title | description
        let titleAndDesc = afterBracket.split(separator: "|", maxSplits: 1).map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let title = titleAndDesc.first ?? ""
        let detail = titleAndDesc.count >= 2 ? titleAndDesc[1] : ""

        guard !title.isEmpty else { return nil }

        return SnagMessage(
            id: id,
            priority: priority,
            floorLabel: floorLabel,
            floor: floorInt,
            trade: trade,
            title: title,
            detail: detail,
            hasPhoto: hasPhoto
        )
    }

    /// Build the wire format string for a snag message (new format with UUID).
    static func wireFormat(
        id: String,
        priority: SnagPriority,
        floor: Int,
        trade: String?,
        title: String,
        description: String?,
        hasPhoto: Bool = false
    ) -> String {
        let floorTag = SiteAlertType.floorTag(for: floor)
        let tradeTag = trade?.uppercased() ?? "UNASSIGNED"
        let photoSuffix = hasPhoto ? ":PHOTO" : ""
        var message = "[SNAG:\(id):\(priority.rawValue):\(floorTag):\(tradeTag)\(photoSuffix)] \(title)"
        if let desc = description, !desc.isEmpty {
            message += " | \(desc)"
        }
        return message
    }

    /// Build a snag photo filename for mesh broadcast.
    /// Format: snag_{timestamp}_{floor}_{priority}.jpg
    static func photoFilename(floor: Int, priority: SnagPriority) -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        let floorTag = SiteAlertType.floorTag(for: floor)
        return "snag_\(timestamp)_\(floorTag)_\(priority.rawValue).jpg"
    }

    /// Convert a tag like "F3" or "FB1" to a readable label like "Floor 3" or "Basement 1"
    private static func readableFloor(from tag: String) -> String? {
        if tag.hasPrefix("FB"), let n = Int(tag.dropFirst(2)) {
            return "Basement \(n)"
        } else if tag.hasPrefix("F"), let n = Int(tag.dropFirst(1)) {
            return n == 0 ? "Ground" : "Floor \(n)"
        }
        return nil
    }

    /// Parse floor tag to integer (e.g. "F3" → 3, "FB1" → -1)
    private static func parseFloorInt(from tag: String) -> Int {
        if tag.hasPrefix("FB"), let n = Int(tag.dropFirst(2)) {
            return -n
        } else if tag.hasPrefix("F"), let n = Int(tag.dropFirst(1)) {
            return n
        }
        return 0
    }
}

#endif
