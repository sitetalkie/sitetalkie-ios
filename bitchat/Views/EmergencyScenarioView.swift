import SwiftUI

#if canImport(Translation)
import Translation
#endif

#if os(iOS)
struct EmergencyScenarioView: View {
    let scenario: ScenarioData
    @EnvironmentObject var siteDataStore: SiteDataStore
    @Environment(\.dismiss) private var dismiss

    // Auto-translation: maps original English text → translated text
    @State private var translations: [String: String] = [:]

    private let backgroundColor = Color(red: 0.055, green: 0.063, blue: 0.071)
    private let cardBackground = Color(red: 0.102, green: 0.110, blue: 0.125)
    private let elevatedBackground = Color(red: 0.141, green: 0.149, blue: 0.157)
    private let borderColor = Color(red: 0.165, green: 0.173, blue: 0.188)
    private let secondaryText = Color(red: 0.541, green: 0.557, blue: 0.588)
    private let tertiaryText = Color(red: 0.353, green: 0.369, blue: 0.400)
    private let amber = Color(red: 0.910, green: 0.588, blue: 0.047)
    private let red = Color(red: 0.898, green: 0.282, blue: 0.302)
    private let green = Color(red: 0.204, green: 0.780, blue: 0.349)
    private let lightCoral = Color(red: 0.941, green: 0.502, blue: 0.502)

    /// Lookup translated text, falling back to original.
    private func t(_ text: String) -> String {
        translations[text] ?? text
    }

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    headerBar

                    // "Translated to [language]" label
                    if !translations.isEmpty {
                        Text("Translated to \(TranslationService.nativeDisplayName(for: TranslationService.shared.preferredLanguage))")
                            .font(.bitchatSystem(size: 9))
                            .foregroundColor(tertiaryText)
                    }

                    call999Banner
                    doNotSection

                    if scenario.interactiveType == .spinalGate {
                        spinalGateView
                    }
                    if let interactive = scenario.interactiveType, interactive != .spinalGate {
                        interactiveCard(interactive)
                    }

                    stepsSection
                    equipmentSection
                    evidenceCard
                    sourcesSection
                    disclaimerFooter
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
        .navigationBarHidden(true)
        .overlay { autoTranslateOverlay }
    }

    // MARK: - Auto-translate (invisible, fires on appear)

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

    private var allTranslatableTexts: [String] {
        var texts: [String] = [scenario.call999Script]
        texts.append(contentsOf: scenario.doNots)
        for step in scenario.steps {
            texts.append(step.title)
            texts.append(step.detail)
        }
        texts.append(scenario.evidenceNote)
        return texts
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.bitchatSystem(size: 15, weight: .semibold))
                    Text("Back")
                        .font(.bitchatSystem(size: 15))
                }
                .foregroundColor(amber)
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 2) {
                Text(scenario.title)
                    .font(.bitchatSystem(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Text(scenario.category)
                    .font(.bitchatSystem(size: 11))
                    .foregroundColor(secondaryText)
            }

            Spacer()
            Color.clear.frame(width: 50, height: 1)
        }
        .padding(.top, 8)
    }

    // MARK: - Call 999 Banner

    private var call999Banner: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "phone.fill")
                    .font(.bitchatSystem(size: 16))
                    .foregroundColor(red)
                Text("Call 999 first")
                    .font(.bitchatSystem(size: 14, weight: .bold))
                    .foregroundColor(red)
            }

            Text(t(scenario.call999Script))
                .font(.bitchatSystem(size: 12))
                .foregroundColor(lightCoral)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(red.opacity(0.12))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(red.opacity(0.33), lineWidth: 1)
        )
    }

    // MARK: - DO NOT Section

    private var doNotSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("DO NOT")
                .font(.bitchatSystem(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(red)
                .kerning(1.2)

            ForEach(Array(scenario.doNots.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "minus.circle.fill")
                        .font(.bitchatSystem(size: 12))
                        .foregroundColor(red)
                        .padding(.top, 2)

                    Text(t(item))
                        .font(.bitchatSystem(size: 12))
                        .foregroundColor(lightCoral)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(4)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(red.opacity(0.12))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(red.opacity(0.33), lineWidth: 1)
        )
    }

    // MARK: - Spinal Gate

    @State private var spinalPulse = true

    private var spinalGateView: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.bitchatSystem(size: 18))
                .foregroundColor(red)

            Text("DO NOT MOVE THE CASUALTY")
                .font(.bitchatSystem(size: 14, weight: .bold))
                .foregroundColor(red)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(red.opacity(0.12))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(red.opacity(0.33), lineWidth: 1)
        )
        .opacity(spinalPulse ? 1.0 : 0.5)
        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: spinalPulse)
        .onAppear { spinalPulse = false }
    }

    // MARK: - Interactive Card

    @ViewBuilder
    private func interactiveCard(_ type: InteractiveType) -> some View {
        VStack(spacing: 0) {
            switch type {
            case .cprMetronome:
                CPRMetronomeView()
            case .flushTimer:
                CountdownTimerView(totalSeconds: 1200, label: "Flush Timer", accentColor: green,
                    note: "Do not stop flushing when pain subsides \u{2014} continue for the full 20 minutes")
            case .coolingTimer:
                CountdownTimerView(totalSeconds: 1200, label: "Cooling Timer", accentColor: amber,
                    note: "Cool water only \u{2014} not ice or iced water")
            case .electricalBranch:
                ElectricalBranchView()
            case .coolingChecklist:
                CoolingChecklistView()
            case .loneWorkerBranch:
                LoneWorkerBranchView()
            case .spinalGate:
                EmptyView()
            }
        }
        .padding(16)
        .background(cardBackground)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderColor, lineWidth: 1))
    }

    // MARK: - Steps

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("STEP-BY-STEP RESPONSE")
                .font(.bitchatSystem(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(tertiaryText)
                .kerning(1.2)

            ForEach(Array(scenario.steps.enumerated()), id: \.element.id) { index, step in
                HStack(alignment: .top, spacing: 12) {
                    Text(String(format: "%02d", index + 1))
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(amber)
                        .frame(width: 20, alignment: .trailing)
                        .padding(.top, 2)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(t(step.title))
                            .font(.bitchatSystem(size: 13, weight: .semibold))
                            .foregroundColor(.white)

                        Text(t(step.detail))
                            .font(.bitchatSystem(size: 12))
                            .foregroundColor(secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(5)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(cardBackground)
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(borderColor, lineWidth: 1))
            }
        }
    }

    // MARK: - Equipment

    private var equipmentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("EQUIPMENT TRIGGERED")
                .font(.bitchatSystem(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(tertiaryText)
                .kerning(1.2)

            ForEach(scenario.equipmentTypes, id: \.self) { eqType in
                let matched = siteDataStore.equipment.filter { $0.equipmentType.uppercased() == eqType.uppercased() }
                if matched.isEmpty {
                    HStack(spacing: 10) {
                        Image(systemName: "cube.box")
                            .font(.bitchatSystem(size: 16))
                            .foregroundColor(tertiaryText)
                            .frame(width: 28)
                        Text(eqType)
                            .font(.bitchatSystem(size: 13))
                            .foregroundColor(tertiaryText)
                        Spacer()
                    }
                    .padding(12).background(cardBackground).cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(borderColor, lineWidth: 1))
                } else {
                    ForEach(matched) { eq in equipmentCard(eq) }
                }
            }
        }
    }

    private func equipmentCard(_ eq: EquipmentLocation) -> some View {
        HStack(spacing: 12) {
            if let photoPath = cachedPhotoPath(for: eq), FileManager.default.fileExists(atPath: photoPath) {
                if let uiImage = UIImage(contentsOfFile: photoPath) {
                    Image(uiImage: uiImage).resizable().aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60).cornerRadius(8).clipped()
                }
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(eq.label).font(.bitchatSystem(size: 13, weight: .semibold)).foregroundColor(.white)
                if let desc = eq.description {
                    Text(desc).font(.bitchatSystem(size: 11)).foregroundColor(secondaryText)
                }
                HStack(spacing: 8) {
                    if let floor = eq.floor {
                        HStack(spacing: 3) {
                            Image(systemName: "building.2").font(.bitchatSystem(size: 9))
                            Text(floor).font(.bitchatSystem(size: 10))
                        }.foregroundColor(tertiaryText)
                    }
                    if let nodeId = eq.nearestNodeId {
                        HStack(spacing: 3) {
                            Image(systemName: "sensor.tag.radiowaves.forward").font(.bitchatSystem(size: 9))
                            Text(nodeId).font(.bitchatSystem(size: 10))
                        }.foregroundColor(tertiaryText)
                    }
                }
            }
            Spacer()
        }
        .padding(12).background(cardBackground).cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(borderColor, lineWidth: 1))
    }

    private func cachedPhotoPath(for eq: EquipmentLocation) -> String? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent("equipment_photo_\(eq.id).jpg").path
    }

    // MARK: - Evidence Note

    private var evidenceCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(t(scenario.evidenceNote))
                .font(.bitchatSystem(size: 11))
                .foregroundColor(secondaryText)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(4)
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
        .background(green.opacity(0.06)).cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(green.opacity(0.2), lineWidth: 1))
    }

    // MARK: - Sources

    private var sourcesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("VERIFICATION SOURCES")
                .font(.bitchatSystem(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(tertiaryText)
                .kerning(1.2)

            VStack(spacing: 0) {
                ForEach(Array(scenario.sources.enumerated()), id: \.offset) { index, source in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(source.name).font(.bitchatSystem(size: 12, weight: .semibold)).foregroundColor(amber)
                        Text(source.note).font(.bitchatSystem(size: 11)).foregroundColor(secondaryText)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if index < scenario.sources.count - 1 {
                        Rectangle().fill(borderColor).frame(height: 1).padding(.horizontal, 14)
                    }
                }
            }
            .background(cardBackground).cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(borderColor, lineWidth: 1))
        }
    }

    // MARK: - Disclaimer

    private var disclaimerFooter: some View {
        VStack(spacing: 4) {
            Text("Not a substitute for first aid training")
                .font(.bitchatSystem(size: 9)).foregroundColor(tertiaryText)
            Text("Health and Safety (First Aid) Regulations 1981")
                .font(.bitchatSystem(size: 9)).foregroundColor(tertiaryText)
        }
        .frame(maxWidth: .infinity).padding(.top, 8)
    }
}
#endif
