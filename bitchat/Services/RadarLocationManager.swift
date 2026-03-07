import Foundation
import CoreLocation

/// Manages compass heading and high-accuracy GPS for the radar view.
/// Separate from LocationStateManager (which uses low accuracy for geohash channels).
///
/// IMPORTANT: CLLocationManager MUST be created and used on the main thread.
/// The singleton can be safely *referenced* from any thread, but `start()`
/// must only be called from the main thread (SwiftUI onAppear guarantees this).
final class RadarLocationManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    static let shared = RadarLocationManager()

    /// Posted once per app session when the first reliable GPS fix (< 100m) arrives.
    /// BLEService observes this to re-announce with location data.
    static let firstReliableGPSFixNotification = Notification.Name("RadarLocationManager.firstReliableGPSFix")

    // MARK: - Published State (for SwiftUI, main thread only)

    @Published var heading: Double = 0           // 0-360, degrees from magnetic north
    @Published var compassDirection: String = "N" // N, NE, E, SE, S, SW, W, NW
    @Published var location: CLLocation?          // High-accuracy GPS fix
    @Published var hasReliableGPS: Bool = false    // True if accuracy < 50m

    // MARK: - Thread-safe reads (for BLEService background access)

    /// Latest GPS latitude — safe to read from any thread.
    /// Keeps last-known-good value when accuracy degrades; cleared after 5 minutes of no good fix.
    private(set) var latestLatitude: Double?
    /// Latest GPS longitude — safe to read from any thread.
    private(set) var latestLongitude: Double?
    /// Latest GPS altitude — safe to read from any thread.
    private(set) var latestAltitude: Double?
    /// True if latest GPS fix has high accuracy (< 50m). Controls green vs amber dots on radar.
    private(set) var latestHasReliableGPS: Bool = false
    /// True if location is usable for broadcasting (< 100m and not stale).
    private(set) var latestHasBroadcastableGPS: Bool = false

    // MARK: - Private

    /// CLLocationManager is created lazily on the main thread in `start()`.
    /// Never created in init to avoid background-thread crashes.
    private var manager: CLLocationManager?
    private var isActive = false
    /// Whether the first-reliable-fix notification has been posted this session.
    private var didFireFirstFix = false
    /// Timestamp of last good GPS fix (accuracy < 100m), for staleness check.
    private var lastGoodFixTime: Date?
    /// Max age before last-known-good coordinates are treated as nil.
    private static let maxStalenessInterval: TimeInterval = 300 // 5 minutes

    private override init() {
        super.init()
        // Do NOT create CLLocationManager here — it must be on the main thread.
        // It will be created lazily in start().
    }

    // MARK: - Start / Stop

    /// Start compass heading and GPS updates. Must be called on the main thread.
    func start() {
        guard !isActive else { return }
        isActive = true

        // Ensure we're on the main thread for CLLocationManager
        if Thread.isMainThread {
            setupAndBegin()
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.setupAndBegin()
            }
        }
    }

    /// Stop all location updates. Safe to call from any thread.
    func stop() {
        guard isActive else { return }
        isActive = false

        if Thread.isMainThread {
            stopUpdatesInternal()
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.stopUpdatesInternal()
            }
        }
    }

    private func setupAndBegin() {
        // Safety: must always be on main thread for CLLocationManager
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in self?.setupAndBegin() }
            return
        }

        // Create CLLocationManager on main thread if needed
        if manager == nil {
            let mgr = CLLocationManager()
            mgr.delegate = self
            mgr.headingFilter = 2 // Update heading every 2 degrees of change
            manager = mgr
        }

        guard let mgr = manager else { return }

        let status: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            status = mgr.authorizationStatus
        } else {
            status = CLLocationManager.authorizationStatus()
        }

        switch status {
        case .notDetermined:
            mgr.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            beginUpdates()
        default:
            // Permission denied/restricted — radar works without location, just no GPS features
            break
        }
    }

    private func beginUpdates() {
        guard let mgr = manager else { return }
        mgr.desiredAccuracy = kCLLocationAccuracyBest
        mgr.distanceFilter = 5 // Update every 5m of movement
        mgr.startUpdatingLocation()

        if CLLocationManager.headingAvailable() {
            mgr.startUpdatingHeading()
        }
    }

    /// Request a single high-accuracy location fix (e.g. when CreatePinView opens).
    func requestSingleLocation() {
        if Thread.isMainThread {
            requestSingleLocationInternal()
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.requestSingleLocationInternal()
            }
        }
    }

    private func requestSingleLocationInternal() {
        guard let mgr = manager else {
            // If manager isn't created yet, start first then request
            setupAndBegin()
            manager?.requestLocation()
            return
        }
        mgr.requestLocation()
    }

    private func stopUpdatesInternal() {
        manager?.stopUpdatingHeading()
        manager?.stopUpdatingLocation()
    }

    // MARK: - CLLocationManagerDelegate

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard newHeading.headingAccuracy >= 0 else { return } // Negative = invalid
        let h = newHeading.magneticHeading
        self.heading = h
        self.compassDirection = Self.directionLabel(for: h)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        let reliable = loc.horizontalAccuracy >= 0 && loc.horizontalAccuracy < 50
        let broadcastable = loc.horizontalAccuracy >= 0 && loc.horizontalAccuracy < 100

        // Update @Published for SwiftUI
        self.location = loc
        self.hasReliableGPS = reliable

        // Update thread-safe values for BLEService
        if broadcastable {
            self.latestLatitude = loc.coordinate.latitude
            self.latestLongitude = loc.coordinate.longitude
            self.latestAltitude = loc.altitude
            self.lastGoodFixTime = Date()
        } else if let lastGood = lastGoodFixTime,
                  Date().timeIntervalSince(lastGood) > Self.maxStalenessInterval {
            // Last good fix is too old — clear coordinates
            self.latestLatitude = nil
            self.latestLongitude = nil
            self.latestAltitude = nil
            self.lastGoodFixTime = nil
        }
        // else: keep last-known-good coordinates (they're still fresh enough)

        self.latestHasReliableGPS = reliable
        self.latestHasBroadcastableGPS = latestLatitude != nil

        // Fire once per session when first broadcastable GPS fix arrives
        if broadcastable && !didFireFirstFix {
            didFireFirstFix = true
            NotificationCenter.default.post(name: Self.firstReliableGPSFixNotification, object: nil)
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if #available(iOS 14.0, *) {
            let status = manager.authorizationStatus
            if isActive && (status == .authorizedWhenInUse || status == .authorizedAlways) {
                beginUpdates()
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if isActive && (status == .authorizedWhenInUse || status == .authorizedAlways) {
            beginUpdates()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Location errors are non-fatal for radar; GPS will show as unavailable
    }

    // MARK: - Helpers

    private static func directionLabel(for degrees: Double) -> String {
        let normalized = degrees.truncatingRemainder(dividingBy: 360)
        switch normalized {
        case 337.5..<360, 0..<22.5:   return "N"
        case 22.5..<67.5:             return "NE"
        case 67.5..<112.5:            return "E"
        case 112.5..<157.5:           return "SE"
        case 157.5..<202.5:           return "S"
        case 202.5..<247.5:           return "SW"
        case 247.5..<292.5:           return "W"
        case 292.5..<337.5:           return "NW"
        default:                      return "N"
        }
    }
}
