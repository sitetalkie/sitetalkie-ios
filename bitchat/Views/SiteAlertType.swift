import SwiftUI

/// Defines the alert types for the Site Alert system — full-screen emergency broadcasts across the BLE mesh.
enum SiteAlertType: String, CaseIterable, Identifiable {
    case fire = "FIRE"
    case warning = "WARNING"
    case medical = "MEDICAL"
    case crane = "CRANE"
    case allClear = "ALL_CLEAR"
    case general = "GENERAL"

    // Emergency types linked to handbook protocols
    case cardiac = "CARDIAC"
    case fall = "FALL"
    case bleeding = "BLEEDING"
    case chemical = "CHEMICAL"
    case electrical = "ELECTRICAL"
    case crush = "CRUSH"
    case burns = "BURNS"
    case confined = "CONFINED"
    case breathing = "BREATHING"
    case heat = "HEAT"
    case loneWorker = "LONE_WORKER"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fire: return "Fire / Evacuation"
        case .warning: return "General Warning"
        case .medical: return "Medical Emergency"
        case .crane: return "Crane / Lifting Op"
        case .allClear: return "All Clear"
        case .general: return "General"
        case .cardiac: return "Cardiac Arrest"
        case .fall: return "Fall from Height"
        case .bleeding: return "Severe Bleeding"
        case .chemical: return "Chemical Splash"
        case .electrical: return "Electrical Contact"
        case .crush: return "Crush Injury"
        case .burns: return "Burns"
        case .confined: return "Confined Space"
        case .breathing: return "Breathing Difficulty"
        case .heat: return "Heat Stroke"
        case .loneWorker: return "Lone Worker"
        }
    }

    var icon: String {
        switch self {
        case .fire: return "flame.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .medical: return "cross.circle.fill"
        case .crane: return "arrow.up.and.down.and.sparkles"
        case .allClear: return "checkmark.shield.fill"
        case .general: return "megaphone.fill"
        case .cardiac: return "heart.slash.fill"
        case .fall: return "figure.fall"
        case .bleeding: return "drop.fill"
        case .chemical: return "flask.fill"
        case .electrical: return "bolt.trianglebadge.exclamationmark.fill"
        case .crush: return "rectangle.compress.vertical"
        case .burns: return "flame.fill"
        case .confined: return "lock.trianglebadge.exclamationmark.fill"
        case .breathing: return "lungs.fill"
        case .heat: return "sun.max.trianglebadge.exclamationmark.fill"
        case .loneWorker: return "person.fill.questionmark"
        }
    }

    var color: Color {
        switch self {
        case .fire: return Color(red: 0.898, green: 0.282, blue: 0.302)       // #E5484D
        case .warning: return Color(red: 0.910, green: 0.588, blue: 0.047)    // #E8960C
        case .medical: return Color(red: 0.231, green: 0.510, blue: 0.965)    // #3B82F6
        case .crane: return Color(red: 0.918, green: 0.702, blue: 0.031)      // #EAB308
        case .allClear: return Color(red: 0.204, green: 0.780, blue: 0.349)   // #34C759
        case .general: return Color(red: 0.631, green: 0.631, blue: 0.667)    // #A1A1AA
        case .cardiac: return Color(red: 0.898, green: 0.282, blue: 0.302)   // #E5484D
        case .fall: return Color(red: 0.898, green: 0.282, blue: 0.302)      // #E5484D
        case .bleeding: return Color(red: 0.898, green: 0.282, blue: 0.302)  // #E5484D
        case .chemical: return Color(red: 0.910, green: 0.588, blue: 0.047)  // #E8960C
        case .electrical: return Color(red: 0.910, green: 0.588, blue: 0.047) // #E8960C
        case .crush: return Color(red: 0.898, green: 0.282, blue: 0.302)     // #E5484D
        case .burns: return Color(red: 0.910, green: 0.588, blue: 0.047)     // #E8960C
        case .confined: return Color(red: 0.898, green: 0.282, blue: 0.302)  // #E5484D
        case .breathing: return Color(red: 0.910, green: 0.588, blue: 0.047) // #E8960C
        case .heat: return Color(red: 0.898, green: 0.282, blue: 0.302)      // #E5484D
        case .loneWorker: return Color(red: 0.541, green: 0.557, blue: 0.588) // #8A8E96
        }
    }

    /// Whether this alert type represents an emergency (affects sound, haptics, and notification priority).
    var isEmergency: Bool {
        switch self {
        case .general, .allClear: return false
        case .fire, .warning, .medical, .crane: return true
        case .cardiac, .fall, .bleeding, .chemical, .electrical,
             .crush, .burns, .confined, .breathing, .heat, .loneWorker:
            return true
        }
    }

    /// The scenario ID linking this alert type to an EmergencyScenarioData entry, if any.
    var scenarioId: String? {
        switch self {
        case .cardiac: return "cardiac"
        case .fall: return "fall"
        case .bleeding: return "bleeding"
        case .chemical: return "chemical"
        case .electrical: return "electrical"
        case .crush: return "crush"
        case .burns: return "burns"
        case .confined: return "confined"
        case .breathing: return "breathing"
        case .heat: return "heat"
        case .loneWorker: return "lone"
        case .fire, .warning, .medical, .crane, .allClear, .general:
            return nil
        }
    }

    /// Whether this alert type has an associated first aid protocol in the Emergency Handbook.
    var hasProtocol: Bool { scenarioId != nil }

    /// The 14 alert types displayed in the SOS composer grid, in display order.
    static var composerTypes: [SiteAlertType] {
        [.cardiac, .fall, .bleeding, .burns, .chemical, .electrical,
         .crush, .breathing, .confined, .heat, .loneWorker,
         .fire, .crane, .warning]
    }

    /// Prefix marker embedded in messages to identify site alerts, e.g. "[SITE_ALERT:FIRE:F3]"
    func messagePrefix(floor: Int) -> String {
        "[SITE_ALERT:\(rawValue):\(Self.floorTag(for: floor))]"
    }

    /// Parse a SiteAlertType from a message content string.
    /// Returns the alert type, optional floor label, and optional detail text.
    /// Handles both "[SITE_ALERT:FIRE]" (legacy) and "[SITE_ALERT:FIRE:F3]" (with floor).
    static func parse(from content: String) -> (alertType: SiteAlertType, floorLabel: String?, detail: String)? {
        guard content.hasPrefix("[SITE_ALERT:") else { return nil }
        guard let closeBracket = content.firstIndex(of: "]") else { return nil }
        let inside = String(content[content.index(content.startIndex, offsetBy: 12)..<closeBracket])
        let detail = String(content[content.index(after: closeBracket)...]).trimmingCharacters(in: .whitespacesAndNewlines)

        let parts = inside.split(separator: ":", maxSplits: 2).map(String.init)
        guard let typePart = parts.first else { return nil }
        let alertType = SiteAlertType(rawValue: typePart) ?? .warning

        let floorLabel: String? = parts.count >= 2 ? Self.readableFloor(from: parts[1]) : nil
        return (alertType, floorLabel, detail)
    }

    /// Convert a floor number to a tag string: 3→"F3", 0→"F0", -1→"FB1", -2→"FB2"
    static func floorTag(for floor: Int) -> String {
        floor < 0 ? "FB\(abs(floor))" : "F\(floor)"
    }

    /// Convert a tag like "F3" or "FB1" to a readable label like "Floor 3" or "Basement 1"
    private static func readableFloor(from tag: String) -> String? {
        if tag.hasPrefix("FB"), let n = Int(tag.dropFirst(2)) {
            return "Basement \(n)"
        } else if tag.hasPrefix("F"), let n = Int(tag.dropFirst(1)) {
            return "Floor \(n)"
        }
        return nil
    }
}
