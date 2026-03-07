import SwiftUI

#if canImport(Translation)
import Translation
#endif

#if os(iOS)
struct EmergencyHandbookView: View {
    @EnvironmentObject var siteDataStore: SiteDataStore
    @Environment(\.dismiss) private var dismiss

    @State private var translations: [String: String] = [:]

    private let backgroundColor = Color(red: 0.055, green: 0.063, blue: 0.071)
    private let cardBackground = Color(red: 0.102, green: 0.110, blue: 0.125)
    private let borderColor = Color(red: 0.165, green: 0.173, blue: 0.188)
    private let secondaryText = Color(red: 0.353, green: 0.369, blue: 0.400)
    private let labelText = Color(red: 0.541, green: 0.557, blue: 0.588)
    private let tertiaryText = Color(red: 0.353, green: 0.369, blue: 0.400)
    private let green = Color(red: 0.204, green: 0.780, blue: 0.349)

    private func t(_ text: String) -> String {
        translations[text] ?? text
    }

    private var scenarios: [ScenarioData] {
        ScenarioData.all(siteAddress: siteDataStore.siteConfig?.siteAddress ?? "[site address not configured]")
    }

    private var allTranslatableTexts: [String] {
        var texts: [String] = []
        for scenario in scenarios {
            texts.append(scenario.title)
            texts.append(scenario.category)
        }
        return texts
    }

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // Close button
                        HStack {
                            Button(action: { dismiss() }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "chevron.left")
                                        .font(.bitchatSystem(size: 15, weight: .semibold))
                                    Text("Settings")
                                        .font(.bitchatSystem(size: 15))
                                }
                                .foregroundColor(Color(red: 0.910, green: 0.588, blue: 0.047))
                            }
                            .buttonStyle(.plain)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                        // Header
                        VStack(spacing: 8) {
                            Text("Emergency Handbook")
                                .font(.bitchatSystem(size: 24, weight: .bold))
                                .foregroundColor(.white)

                            Text(siteDataStore.siteConfig?.siteName ?? "Emergency Handbook")
                                .font(.bitchatSystem(size: 13))
                                .foregroundColor(labelText)

                            HStack(spacing: 6) {
                                Circle()
                                    .fill(green)
                                    .frame(width: 6, height: 6)
                                Text("Offline \u{2014} all protocols available")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(green)
                            }
                            .padding(.top, 4)
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 24)

                        // Scenario list
                        VStack(spacing: 1) {
                            ForEach(scenarios) { scenario in
                                NavigationLink(destination: EmergencyScenarioView(scenario: scenario)) {
                                    scenarioRow(scenario)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .background(cardBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(borderColor, lineWidth: 1)
                        )
                        .padding(.horizontal, 16)

                        // Footer
                        VStack(spacing: 4) {
                            Text("Not a substitute for first aid training")
                                .font(.bitchatSystem(size: 10))
                                .foregroundColor(secondaryText)
                            Text("Health and Safety (First Aid) Regulations 1981")
                                .font(.bitchatSystem(size: 10))
                                .foregroundColor(secondaryText)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 24)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationBarHidden(true)
            .overlay { autoTranslateOverlay }
        }
    }

    @ViewBuilder
    private var autoTranslateOverlay: some View {
        if #available(iOS 18.0, *),
           TranslationService.shared.isTranslationAvailable,
           !TranslationService.shared.isEnglish {
            BatchTranslateTask(texts: allTranslatableTexts) { results in
                translations = results
            }
        }
    }

    private func scenarioRow(_ scenario: ScenarioData) -> some View {
        HStack(spacing: 0) {
            // Colored left bar
            RoundedRectangle(cornerRadius: 1.5)
                .fill(scenario.categoryColor)
                .frame(width: 3)
                .padding(.vertical, 8)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(t(scenario.title))
                        .font(.bitchatSystem(size: 15, weight: .semibold))
                        .foregroundColor(.white)

                    Text(t(scenario.category))
                        .font(.bitchatSystem(size: 11))
                        .foregroundColor(labelText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.bitchatSystem(size: 13, weight: .semibold))
                    .foregroundColor(secondaryText)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
        }
        .frame(minHeight: 48)
        .background(cardBackground)
    }
}
#endif
