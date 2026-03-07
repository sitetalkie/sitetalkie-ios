//
// PinDistanceTracker.swift
// bitchat
//
// Reactive distance tracking from the user to all site pins.
// Subscribes to RadarLocationManager updates and publishes a distance dictionary.
//

import Foundation
import CoreLocation
import Combine

#if os(iOS)

/// GPS state for distance display
enum GPSState: Equatable {
    case available          // Accuracy < 50m — reliable
    case approximate        // Accuracy 50-100m — show with tilde
    case poor               // Accuracy > 100m — too rough for specific distance
    case locating           // Awaiting first fix
    case permissionDenied   // Location permission denied
    case unavailable        // No location at all
}

final class PinDistanceTracker: ObservableObject {
    static let shared = PinDistanceTracker()

    /// Distance in metres from user to each pin, keyed by pin ID
    @Published var distances: [String: Double] = [:]

    /// Current GPS state
    @Published var gpsState: GPSState = .locating

    /// GPS horizontal accuracy in metres (for approximate display)
    @Published var accuracy: Double = .infinity

    private var cancellables = Set<AnyCancellable>()
    private var lastComputedLocation: CLLocation?

    /// Minimum location change in metres before recalculating distances
    private static let jitterFilterMetres: Double = 5.0
    /// Maximum distance to compute (skip pins beyond this)
    private static let maxTrackingDistanceMetres: Double = 5000.0

    private init() {
        // Subscribe to location changes from RadarLocationManager
        RadarLocationManager.shared.$location
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                self?.handleLocationUpdate(location)
            }
            .store(in: &cancellables)

        // Subscribe to pin changes from SitePinManager
        SitePinManager.shared.$pins
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.recalculate()
            }
            .store(in: &cancellables)

        // Initial state check
        updateGPSState()
    }

    // MARK: - Location Update

    private func handleLocationUpdate(_ location: CLLocation?) {
        guard let loc = location else {
            updateGPSState()
            return
        }

        // Update GPS state based on accuracy
        let acc = loc.horizontalAccuracy
        accuracy = acc
        if acc < 0 {
            gpsState = .locating
        } else if acc < 50 {
            gpsState = .available
        } else if acc <= 100 {
            gpsState = .approximate
        } else {
            gpsState = .poor
        }

        // Filter minor GPS jitter
        if let last = lastComputedLocation,
           loc.distance(from: last) < Self.jitterFilterMetres {
            return
        }

        lastComputedLocation = loc
        recalculate()
    }

    private func updateGPSState() {
        let mgr = CLLocationManager()
        let status: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            status = mgr.authorizationStatus
        } else {
            status = CLLocationManager.authorizationStatus()
        }

        switch status {
        case .denied, .restricted:
            gpsState = .permissionDenied
        case .notDetermined:
            gpsState = .locating
        default:
            if RadarLocationManager.shared.location == nil {
                gpsState = .locating
            }
        }
    }

    // MARK: - Distance Calculation

    private func recalculate() {
        guard let userLoc = RadarLocationManager.shared.location else {
            distances = [:]
            return
        }

        var newDistances: [String: Double] = [:]
        for pin in SitePinManager.shared.pins {
            let pinLoc = CLLocation(latitude: pin.latitude, longitude: pin.longitude)
            let dist = userLoc.distance(from: pinLoc)
            if dist <= Self.maxTrackingDistanceMetres {
                newDistances[pin.id] = dist
            }
        }
        distances = newDistances
    }

    // MARK: - Formatted Distance

    /// Format a distance for display, accounting for GPS state
    func formattedDistance(for pinID: String) -> (text: String, color: DistanceDisplayColor) {
        switch gpsState {
        case .permissionDenied:
            return ("Enable location for distance", .dimmed)
        case .locating:
            return ("Locating...", .secondary)
        case .poor:
            return ("Approximate location", .secondary)
        case .approximate:
            if let dist = distances[pinID] {
                return ("~\(formatMetres(dist)) (approx)", .secondary)
            }
            return ("Approximate location", .secondary)
        case .available:
            if let dist = distances[pinID] {
                return ("~\(formatMetres(dist)) away", .secondary)
            }
            return ("Distance unavailable", .dimmed)
        case .unavailable:
            return ("Distance unavailable", .dimmed)
        }
    }

    private func formatMetres(_ distance: Double) -> String {
        if distance < 1000 {
            return "\(Int(distance))m"
        } else {
            return String(format: "%.1fkm", distance / 1000)
        }
    }
}

/// Color intent for distance display text
enum DistanceDisplayColor {
    case secondary  // #8A8E96
    case dimmed     // #5A5E66
}

#endif
