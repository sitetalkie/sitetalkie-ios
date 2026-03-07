//
// MainTabView.swift
// bitchat
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import SwiftUI

#if os(iOS)

/// Renders a 44pt red circle with a white exclamationmark.triangle.fill baked in.
/// Uses .alwaysOriginal so iOS never applies tint/liquid animation recoloring.
private func makeSOSTabImage() -> UIImage {
    let size = CGSize(width: 44, height: 44)
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { _ in
        // Red circle
        UIColor(red: 229/255, green: 72/255, blue: 77/255, alpha: 1).setFill()
        UIBezierPath(ovalIn: CGRect(origin: .zero, size: size)).fill()

        // White warning icon centered
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        if let symbol = UIImage(systemName: "exclamationmark.triangle.fill", withConfiguration: config) {
            let tinted = symbol.withTintColor(.white, renderingMode: .alwaysOriginal)
            let iconSize = tinted.size
            let origin = CGPoint(
                x: (size.width - iconSize.width) / 2,
                y: (size.height - iconSize.height) / 2
            )
            tinted.draw(at: origin)
        }
    }.withRenderingMode(.alwaysOriginal)
}

struct MainTabView: View {
    @EnvironmentObject var viewModel: ChatViewModel
    @EnvironmentObject var alertNavigationState: AlertNavigationState
    @EnvironmentObject var siteDataStore: SiteDataStore
    @State private var selectedTab = 0
    @State private var previousTab = 0
    @State private var showSOSSheet = false

    private let activeColor = Color(red: 0.910, green: 0.588, blue: 0.047) // #E8960C

    init() {
        let bg = UIColor(red: 0.102, green: 0.110, blue: 0.125, alpha: 1)    // #1A1C20
        let border = UIColor(red: 0.165, green: 0.173, blue: 0.188, alpha: 1) // #2A2C30
        let active = UIColor(red: 0.910, green: 0.588, blue: 0.047, alpha: 1) // #E8960C
        let inactive = UIColor(red: 0.353, green: 0.369, blue: 0.400, alpha: 1) // #5A5E66

        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = bg
        tabBarAppearance.shadowColor = border // 1px top border

        // Active tab
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: active]
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = active

        // Inactive tab
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: inactive]
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = inactive

        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        UITabBar.appearance().isTranslucent = false
        UITabBar.appearance().barTintColor = bg
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            ContentView()
                .environmentObject(viewModel)
                .tabItem {
                    Image(systemName: "message.fill")
                    Text("Chat")
                }
                .tag(0)

            PeopleListView(selectedTab: $selectedTab)
                .environmentObject(viewModel)
                .tabItem {
                    Image(systemName: "person.2.fill")
                    Text("People")
                }
                .tag(1)

            // SOS tab — intercepted on tap, never actually displayed
            Color.clear
                .tabItem {
                    Image(uiImage: makeSOSTabImage())
                }
                .tag(2)

            SiteTabView()
                .environmentObject(viewModel)
                .tabItem {
                    Image(systemName: "mappin.and.ellipse")
                    Text("Site")
                }
                .tag(3)

            SettingsView()
                .environmentObject(viewModel)
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
                .tag(4)
        }
        .tint(activeColor)
        .preferredColorScheme(.dark)
        .onChange(of: selectedTab) { newTab in
            if newTab == 2 {
                // SOS tapped — present sheet and snap back to previous tab
                selectedTab = previousTab
                showSOSSheet = true
            } else {
                previousTab = newTab
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToSiteTab)) { _ in
            selectedTab = 3
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToBulletin)) { _ in
            selectedTab = 3
        }
        .fullScreenCover(isPresented: Binding(
            get: { alertNavigationState.activeScenarioId != nil },
            set: { if !$0 { alertNavigationState.activeScenarioId = nil } }
        )) {
            if let scenarioId = alertNavigationState.activeScenarioId {
                let scenarios = ScenarioData.all(siteAddress: siteDataStore.siteConfig?.siteAddress ?? "")
                if let scenario = scenarios.first(where: { $0.id == scenarioId }) {
                    NavigationStack {
                        EmergencyScenarioView(scenario: scenario)
                            .environmentObject(siteDataStore)
                    }
                }
            }
        }
        .sheet(isPresented: $showSOSSheet) {
            SiteAlertComposerView()
                .environmentObject(viewModel)
                .environmentObject(alertNavigationState)
        }
    }
}
#endif
