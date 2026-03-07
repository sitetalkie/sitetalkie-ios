//
// PinGeofenceManager.swift
// bitchat
//
// Manages CLCircularRegion geofences for site pins.
// Handles foreground banners and background local notifications on region entry.
//

import Foundation
import CoreLocation
import UIKit

#if os(iOS)

final class PinGeofenceManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    static let shared = PinGeofenceManager()

    /// Maximum concurrent geofences iOS allows
    private static let maxGeofences = 20

    private var locationManager: CLLocationManager?

    /// Currently showing banner pin (for foreground alerts)
    @Published var activeBannerPin: SitePin?

    private override init() {
        super.init()
    }

    // MARK: - Setup

    private func ensureManager() -> CLLocationManager {
        if let mgr = locationManager { return mgr }
        let mgr = CLLocationManager()
        mgr.delegate = self
        mgr.allowsBackgroundLocationUpdates = false
        locationManager = mgr
        return mgr
    }

    // MARK: - Register / Remove

    func registerGeofence(for pin: SitePin) {
        DispatchQueue.main.async { [weak self] in
            self?.registerGeofenceInternal(for: pin)
        }
    }

    private func registerGeofenceInternal(for pin: SitePin) {
        let mgr = ensureManager()

        // Check if already at limit; if so, only register if higher priority
        let currentCount = mgr.monitoredRegions.count
        if currentCount >= Self.maxGeofences {
            // Find lowest priority existing region
            let allPins = SitePinManager.shared.pins
            var lowestPriority: (region: CLRegion, priority: Int)?
            for region in mgr.monitoredRegions {
                if let existingPin = allPins.first(where: { $0.id == region.identifier }) {
                    let pri = existingPin.type.geofencePriority
                    if lowestPriority == nil || pri > lowestPriority!.priority {
                        lowestPriority = (region, pri)
                    }
                }
            }

            // Only replace if new pin is higher priority
            if let lowest = lowestPriority, pin.type.geofencePriority < lowest.priority {
                mgr.stopMonitoring(for: lowest.region)
            } else {
                return // Can't fit, and new pin isn't higher priority
            }
        }

        let region = CLCircularRegion(
            center: CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude),
            radius: pin.radius,
            identifier: pin.id
        )
        region.notifyOnEntry = true
        region.notifyOnExit = false

        mgr.startMonitoring(for: region)
    }

    func removeGeofence(for pin: SitePin) {
        DispatchQueue.main.async { [weak self] in
            guard let mgr = self?.locationManager else { return }
            for region in mgr.monitoredRegions where region.identifier == pin.id {
                mgr.stopMonitoring(for: region)
            }
        }
    }

    func registerAllGeofences(for pins: [SitePin]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let mgr = self.ensureManager()

            // Clear all existing pin geofences
            for region in mgr.monitoredRegions {
                mgr.stopMonitoring(for: region)
            }

            // Sort by priority (hazard first), take top 20
            let sorted = pins
                .filter { !$0.isResolved }
                .sorted { $0.type.geofencePriority < $1.type.geofencePriority }

            for pin in sorted.prefix(Self.maxGeofences) {
                let region = CLCircularRegion(
                    center: CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude),
                    radius: pin.radius,
                    identifier: pin.id
                )
                region.notifyOnEntry = true
                region.notifyOnExit = false
                mgr.startMonitoring(for: region)
            }
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let circularRegion = region as? CLCircularRegion else { return }

        let pin = SitePinManager.shared.pins.first { $0.id == circularRegion.identifier }
        guard let pin = pin else { return }

        let appState = UIApplication.shared.applicationState

        if appState == .active {
            // Foreground: show banner + haptic
            DispatchQueue.main.async { [weak self] in
                self?.showBanner(for: pin)
                self?.triggerHaptic(for: pin.type)
            }
        } else {
            // Background: local notification
            sendBackgroundNotification(for: pin)
        }
    }

    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        // Geofence monitoring failed — non-fatal
    }

    // MARK: - Foreground Banner

    private func showBanner(for pin: SitePin) {
        activeBannerPin = pin
        // Auto-dismiss after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            if self?.activeBannerPin?.id == pin.id {
                self?.activeBannerPin = nil
            }
        }
    }

    private func triggerHaptic(for type: PinType) {
        let generator = UINotificationFeedbackGenerator()
        switch type {
        case .hazard:
            generator.notificationOccurred(.error)
        case .snag:
            generator.notificationOccurred(.warning)
        case .note, .safeZone:
            generator.notificationOccurred(.success)
        }
    }

    // MARK: - Background Notification

    private func sendBackgroundNotification(for pin: SitePin) {
        let title: String
        let sound: UNNotificationSound?

        switch pin.type {
        case .hazard:
            title = "\u{26A0}\u{FE0F} Hazard Nearby"
            sound = .default
        case .snag:
            title = "Snag Nearby"
            sound = nil
        case .note:
            title = "Note Nearby"
            sound = nil
        case .safeZone:
            title = "Safe Zone"
            sound = nil
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = pin.title
        if let s = sound {
            content.sound = s
        }
        content.userInfo = ["pinID": pin.id]

        let request = UNNotificationRequest(
            identifier: "pin-geofence-\(pin.id)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}

#endif
