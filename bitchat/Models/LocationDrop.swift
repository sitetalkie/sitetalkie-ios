import Foundation
import CoreLocation

struct LocationDrop: Codable, Identifiable {
    let id: UUID
    let senderID: String        // BLE peer ID
    let senderName: String      // Display name
    let senderTrade: String?    // Trade badge
    let timestamp: Date

    // Location fields (all user-entered, NOT from GPS)
    let floor: String           // "Level 3", "B1", "Roof", "Ground"
    let zone: String            // "East side, riser cupboard"
    let nearLandmark: String?   // "Stairwell", "Lift", "Core", etc.
    let message: String?        // Optional additional context
    let hasPhoto: Bool          // Photo attached flag

    // Optional GPS if available (for future SiteNode proximity matching)
    let latitude: Double?
    let longitude: Double?

    // Alert level
    let isEmergency: Bool       // true = red "HELP NEEDED" styling
}
