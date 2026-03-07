import Foundation
import CoreLocation

/// Peer distance calculation utilities.
/// Provides zone labels ("Right here", "Close", "Nearby", "On site") and raw metre values
/// for the People list.
enum RadarPeerPosition {

    // MARK: - Distance Helpers

    /// Haversine distance in meters between two coordinates.
    static func distance(from src: CLLocationCoordinate2D, to dst: CLLocationCoordinate2D) -> Double {
        let R = 6371000.0 // Earth radius in meters
        let lat1 = src.latitude * .pi / 180
        let lat2 = dst.latitude * .pi / 180
        let dLat = lat2 - lat1
        let dLon = (dst.longitude - src.longitude) * .pi / 180

        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return R * c
    }

    // MARK: - Distance Source

    enum DistanceSource {
        case gps
        case rssi
        case connectionState
    }

    // MARK: - PeerDistance

    struct PeerDistance {
        let metres: Double
        let source: DistanceSource
        let label: String
        let isColocated: Bool
    }

    // MARK: - Zone Label Formatting

    /// Format a distance as a zone name.
    static func formatZoneLabel(metres: Double, source: DistanceSource) -> String {
        if source == .gps && metres < 1.0 {
            return "Right here"
        } else if metres < 10.0 {
            return "Close"
        } else if metres < 30.0 {
            return "Nearby"
        } else {
            return "On site"
        }
    }

    // MARK: - RSSI to Metres Estimate

    /// Convert RSSI to an estimated distance in metres that maps to zone rings.
    /// > -50 dBm -> Close zone, -50 to -75 dBm -> Nearby zone, < -75 dBm -> On Site zone
    private static func rssiToMetres(_ rssi: Int) -> Double {
        if rssi > -50 { return 5 }      // Close (< 10m)
        if rssi >= -65 { return 15 }    // Nearby (10-30m)
        if rssi >= -75 { return 25 }    // Nearby (10-30m)
        return 35                        // On Site (30m+)
    }

    /// Estimate metres from connection state (no RSSI available).
    private static func connectionStateToMetres(_ peer: BitchatPeer) -> Double {
        switch peer.connectionState {
        case .bluetoothConnected: return 5
        case .meshReachable:     return 20
        default:                 return 15
        }
    }

    // MARK: - Compute PeerDistance (single entry point)

    /// Compute distance for a single peer. Uses GPS when both user and peer have coordinates,
    /// otherwise falls back to RSSI or connection state.
    static func computePeerDistance(
        peer: BitchatPeer,
        myLocation: CLLocation?
    ) -> PeerDistance {
        let metres: Double
        let source: DistanceSource
        let label: String

        if let myLoc = myLocation,
           myLoc.horizontalAccuracy >= 0, myLoc.horizontalAccuracy < 200,
           let peerLat = peer.latitude, let peerLon = peer.longitude {
            // GPS path
            let peerCoord = CLLocationCoordinate2D(latitude: peerLat, longitude: peerLon)
            metres = distance(from: myLoc.coordinate, to: peerCoord)
            source = .gps
        } else if let rssi = peer.rssi {
            // RSSI path
            metres = rssiToMetres(rssi)
            source = .rssi
        } else {
            // Connection state path
            metres = connectionStateToMetres(peer)
            source = .connectionState
        }

        label = formatZoneLabel(metres: metres, source: source)

        return PeerDistance(
            metres: metres,
            source: source,
            label: label,
            isColocated: source == .gps && metres < 1
        )
    }

    // MARK: - People List Helpers

    /// Compute a zone label for display in PeopleListView.
    /// Returns nil when no meaningful distance can be shown.
    static func distanceLabelForPeopleList(peer: BitchatPeer, myLocation: CLLocation?) -> String? {
        let pd = computePeerDistance(peer: peer, myLocation: myLocation)
        switch pd.source {
        case .gps, .rssi:
            return pd.label
        case .connectionState:
            return nil
        }
    }

    /// Raw distance in metres for sorting. Returns nil for connection-state-only estimates.
    static func distanceMetres(peer: BitchatPeer, myLocation: CLLocation?) -> Double? {
        let pd = computePeerDistance(peer: peer, myLocation: myLocation)
        switch pd.source {
        case .gps, .rssi:
            return pd.metres
        case .connectionState:
            return nil
        }
    }
}
