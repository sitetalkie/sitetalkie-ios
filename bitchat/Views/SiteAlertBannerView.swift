import SwiftUI

#if canImport(Translation)
import Translation
#endif

/// In-chat card for a Site Alert message. Renders as a full-width coloured card
/// instead of a normal chat bubble so alerts are visually distinct in chat history.
struct SiteAlertBannerView: View {
    let alertType: SiteAlertType
    let floorLabel: String?
    let detail: String
    let senderName: String
    let timestamp: String
    var scenarioTitle: String? = nil
    var onOpenProtocol: (() -> Void)? = nil

    @State private var translatedDetail: String?

    private let amberColor = Color(red: 0.910, green: 0.588, blue: 0.047) // #E8960C

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Icon + alert type name
            HStack(spacing: 8) {
                Image(systemName: alertType.icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(alertType.color)

                Text(alertType.displayName.uppercased())
                    .font(.bitchatSystem(size: 16, weight: .bold))
                    .foregroundColor(alertType.color)

                Spacer()
            }

            // Scenario title + handbook link
            if let title = scenarioTitle {
                Text(title)
                    .font(.bitchatSystem(size: 13, weight: .medium))
                    .foregroundColor(alertType.color.opacity(0.85))

                if let openProtocol = onOpenProtocol {
                    Button(action: openProtocol) {
                        Text("See Emergency Handbook")
                            .font(.bitchatSystem(size: 12, weight: .semibold))
                            .foregroundColor(amberColor)
                            .underline()
                    }
                    .buttonStyle(.plain)
                }
            }

            // Floor label
            if let floorLabel = floorLabel {
                Text(floorLabel)
                    .font(.bitchatSystem(size: 14, weight: .semibold))
                    .foregroundColor(alertType.color.opacity(0.85))
            }

            // Detail text
            if !detail.isEmpty {
                Text(translatedDetail ?? detail)
                    .font(.bitchatSystem(size: 15))
                    .foregroundColor(Color(red: 0.941, green: 0.941, blue: 0.941)) // #F0F0F0
            }

            // Sender + timestamp
            HStack(spacing: 6) {
                Text(senderName)
                    .font(.bitchatSystem(size: 12))
                    .foregroundColor(Color(red: 0.541, green: 0.557, blue: 0.588)) // #8A8E96

                Text("·")
                    .font(.bitchatSystem(size: 12))
                    .foregroundColor(Color(red: 0.541, green: 0.557, blue: 0.588))

                Text(timestamp)
                    .font(.bitchatSystem(size: 12))
                    .foregroundColor(Color(red: 0.541, green: 0.557, blue: 0.588))
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(alertType.color.opacity(0.10))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(alertType.color, lineWidth: 3)
        )
        .padding(.horizontal, 8)
        .overlay { autoTranslateOverlay }
    }

    @ViewBuilder
    private var autoTranslateOverlay: some View {
        #if os(iOS)
        if #available(iOS 18.0, *),
           !detail.isEmpty,
           TranslationService.shared.isTranslationAvailable,
           !TranslationService.shared.isEnglish {
            AutoTranslateTask(text: detail) { translated in
                translatedDetail = translated
            }
        }
        #endif
    }
}
