//
// SitePinManager.swift
// bitchat
//
// Singleton managing persistence and CRUD for site location pins.
//

import Foundation
import Combine

#if os(iOS)

final class SitePinManager: ObservableObject {
    static let shared = SitePinManager()

    private static let storageKey = "sitetalkie.pins"

    @Published var pins: [SitePin] = []

    /// Callback invoked for each pin that expires, with the pin's title.
    var onPinExpired: ((String) -> Void)?

    private init() {
        loadPins()
    }

    // MARK: - Persistence

    func loadPins() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              var decoded = try? JSONDecoder().decode([SitePin].self, from: data) else {
            pins = []
            return
        }

        // Part 7: remove expired pins on load
        let now = Date()
        let (valid, expired) = decoded.reduce(into: ([SitePin](), [SitePin]())) { result, pin in
            if let exp = pin.expiresAt, exp < now {
                result.1.append(pin)
            } else {
                result.0.append(pin)
            }
        }

        // Remove geofences for expired pins and notify
        for pin in expired {
            PinGeofenceManager.shared.removeGeofence(for: pin)
            onPinExpired?(pin.title)
        }

        if expired.count > 0 {
            decoded = valid
            savePinsInternal(decoded)
        }

        pins = decoded
    }

    func savePins() {
        savePinsInternal(pins)
    }

    private func savePinsInternal(_ list: [SitePin]) {
        if let data = try? JSONEncoder().encode(list) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    // MARK: - CRUD

    func addPin(_ pin: SitePin) {
        // Avoid duplicates by id
        guard !pins.contains(where: { $0.id == pin.id }) else { return }
        pins.append(pin)
        savePins()
        PinGeofenceManager.shared.registerGeofence(for: pin)
    }

    func removePin(_ pin: SitePin) {
        pins.removeAll { $0.id == pin.id }
        savePins()
        PinGeofenceManager.shared.removeGeofence(for: pin)
    }

    func resolvePin(_ pin: SitePin) {
        guard let idx = pins.firstIndex(where: { $0.id == pin.id }) else { return }
        pins[idx].isResolved = true
        savePins()
        PinGeofenceManager.shared.removeGeofence(for: pin)
    }

    func extendPin(_ pin: SitePin, by interval: TimeInterval = 86400) {
        guard let idx = pins.firstIndex(where: { $0.id == pin.id }) else { return }
        let current = pins[idx].expiresAt ?? Date()
        pins[idx].expiresAt = current.addingTimeInterval(interval)
        savePins()
    }

    /// Re-register all geofences (called on app launch)
    func reRegisterAllGeofences() {
        PinGeofenceManager.shared.registerAllGeofences(for: pins)
    }
}

#endif
