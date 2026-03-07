import SwiftUI

#if os(iOS)
struct LoneWorkerBranchView: View {
    enum Condition: CaseIterable {
        case notBreathing
        case severebleeding
        case conscious
        case unconsciousBreathing

        var title: String {
            switch self {
            case .notBreathing: return "Not breathing"
            case .severebleeding: return "Severe bleeding"
            case .conscious: return "Conscious"
            case .unconsciousBreathing: return "Unconscious, breathing"
            }
        }

        var color: Color {
            switch self {
            case .notBreathing: return Color(red: 0.898, green: 0.282, blue: 0.302)
            case .severebleeding: return Color(red: 0.910, green: 0.588, blue: 0.047)
            case .conscious: return Color(red: 0.204, green: 0.780, blue: 0.349)
            case .unconsciousBreathing: return Color(red: 0.541, green: 0.557, blue: 0.588)
            }
        }

        var icon: String {
            switch self {
            case .notBreathing: return "lungs.fill"
            case .severebleeding: return "drop.fill"
            case .conscious: return "person.fill"
            case .unconsciousBreathing: return "person.fill.turn.down"
            }
        }

        var redirect: String {
            switch self {
            case .notBreathing: return "Cardiac Arrest protocol \u{2014} CPR immediately"
            case .severebleeding: return "Severe Bleeding protocol \u{2014} direct pressure now"
            case .conscious: return "Assess injuries. Reassure. Do not move."
            case .unconsciousBreathing: return "Recovery position. Monitor airway. Await 999."
            }
        }
    }

    @State private var selected: Condition?

    private let tertiaryText = Color(red: 0.353, green: 0.369, blue: 0.400)
    private let elevatedBackground = Color(red: 0.141, green: 0.149, blue: 0.157)

    var body: some View {
        VStack(spacing: 12) {
            Text("WHAT DID YOU FIND?")
                .font(.bitchatSystem(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(tertiaryText)
                .kerning(1.2)

            // 2x2 grid
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(Condition.allCases, id: \.self) { condition in
                    Button(action: { withAnimation { selected = condition } }) {
                        VStack(spacing: 8) {
                            Image(systemName: condition.icon)
                                .font(.bitchatSystem(size: 22))
                                .foregroundColor(selected == condition ? .white : condition.color)

                            Text(condition.title)
                                .font(.bitchatSystem(size: 12, weight: .semibold))
                                .foregroundColor(selected == condition ? .white : condition.color)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 80)
                        .background(
                            selected == condition
                                ? condition.color.opacity(0.25)
                                : condition.color.opacity(0.08)
                        )
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(
                                    selected == condition ? condition.color : condition.color.opacity(0.2),
                                    lineWidth: selected == condition ? 2 : 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            // Redirect text
            if let condition = selected {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.bitchatSystem(size: 14))
                        .foregroundColor(condition.color)

                    Text(condition.redirect)
                        .font(.bitchatSystem(size: 13, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(condition.color.opacity(0.1))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(condition.color.opacity(0.2), lineWidth: 1)
                )
                .transition(.opacity.combined(with: .offset(y: 8)))
            }
        }
        .padding(.vertical, 8)
    }
}
#endif
