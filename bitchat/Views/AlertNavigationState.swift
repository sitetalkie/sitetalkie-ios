import SwiftUI

/// Shared navigation state for presenting EmergencyScenarioView from overlays, banners, or the composer.
final class AlertNavigationState: ObservableObject {
    /// When set to a non-nil scenario ID, MainTabView presents the corresponding EmergencyScenarioView.
    @Published var activeScenarioId: String?

    func openProtocol(scenarioId: String) {
        activeScenarioId = scenarioId
    }

    func dismissProtocol() {
        activeScenarioId = nil
    }
}
