import SwiftUI

#if os(iOS)
struct CoolingChecklistView: View {
    @State private var checked: Set<Int> = []

    private let items = [
        "Remove excess clothing",
        "Move to shade or cool area",
        "Apply cool water to skin",
        "Ice packs \u{2014} neck, armpits, groin",
        "Fan continuously",
        "Wet cloth on forehead"
    ]

    private let amber = Color(red: 0.910, green: 0.588, blue: 0.047)
    private let green = Color(red: 0.204, green: 0.780, blue: 0.349)
    private let elevatedBackground = Color(red: 0.141, green: 0.149, blue: 0.157)
    private let secondaryText = Color(red: 0.541, green: 0.557, blue: 0.588)
    private let tertiaryText = Color(red: 0.353, green: 0.369, blue: 0.400)

    private var progress: CGFloat {
        CGFloat(checked.count) / CGFloat(items.count)
    }

    private var progressColor: Color {
        checked.count == items.count ? green : amber
    }

    var body: some View {
        VStack(spacing: 14) {
            // Progress bar
            HStack {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(elevatedBackground)
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 3)
                            .fill(progressColor)
                            .frame(width: geo.size.width * progress, height: 6)
                            .animation(.easeInOut(duration: 0.3), value: progress)
                    }
                }
                .frame(height: 6)

                Text("\(checked.count)/\(items.count)")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(secondaryText)
                    .frame(width: 30, alignment: .trailing)
            }

            // Checklist items
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                Button(action: { toggleItem(index) }) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .stroke(checked.contains(index) ? green : tertiaryText, lineWidth: 1.5)
                                .frame(width: 18, height: 18)

                            if checked.contains(index) {
                                Circle()
                                    .fill(green)
                                    .frame(width: 18, height: 18)

                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }

                        Text(item)
                            .font(.bitchatSystem(size: 13))
                            .foregroundColor(checked.contains(index) ? secondaryText : .white)
                            .strikethrough(checked.contains(index), color: secondaryText)

                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(elevatedBackground)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(checked.contains(index) ? green.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }

            // All checked message
            if checked.count == items.count {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.bitchatSystem(size: 14))
                        .foregroundColor(green)
                    Text("All cooling methods active \u{2014} do not leave casualty unattended")
                        .font(.bitchatSystem(size: 12, weight: .medium))
                        .foregroundColor(green)
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(green.opacity(0.08))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(green.opacity(0.2), lineWidth: 1)
                )
            }

            // Note
            Text("Do not use ice-cold water immersion \u{2014} cool water only")
                .font(.bitchatSystem(size: 11))
                .foregroundColor(tertiaryText)
        }
        .padding(.vertical, 8)
    }

    private func toggleItem(_ index: Int) {
        if checked.contains(index) {
            checked.remove(index)
        } else {
            checked.insert(index)
        }
    }
}
#endif
