import SwiftUI

#if os(iOS)
struct ElectricalBranchView: View {
    enum VoltageSelection {
        case none
        case low
        case high
    }

    @State private var selection: VoltageSelection = .none

    private let amber = Color(red: 0.910, green: 0.588, blue: 0.047)
    private let red = Color(red: 0.898, green: 0.282, blue: 0.302)
    private let cardBackground = Color(red: 0.102, green: 0.110, blue: 0.125)
    private let elevatedBackground = Color(red: 0.141, green: 0.149, blue: 0.157)
    private let secondaryText = Color(red: 0.541, green: 0.557, blue: 0.588)
    private let tertiaryText = Color(red: 0.353, green: 0.369, blue: 0.400)

    private let highVoltageSteps = [
        "Keep everyone back 25m",
        "Call 999 and grid operator/DNO",
        "No entry to the zone",
        "Once isolated: treat as low voltage"
    ]

    private let lowVoltageSteps = [
        "Isolate at source",
        "Cannot isolate? Use dry non-conductive item",
        "Assess once isolated \u{2014} CPR if needed",
        "Burns \u{2014} dry sterile dressing only, no water"
    ]

    @State private var showWarningPulse = true

    var body: some View {
        VStack(spacing: 16) {
            Text("SELECT VOLTAGE TYPE")
                .font(.bitchatSystem(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(tertiaryText)
                .kerning(1.2)

            HStack(spacing: 12) {
                Button(action: { withAnimation { selection = .low } }) {
                    VStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                            .font(.bitchatSystem(size: 22))
                        Text("Low Voltage")
                            .font(.bitchatSystem(size: 13, weight: .semibold))
                    }
                    .foregroundColor(selection == .low ? .black : amber)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(selection == .low ? amber : amber.opacity(0.1))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(amber.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                Button(action: { withAnimation { selection = .high } }) {
                    VStack(spacing: 6) {
                        Image(systemName: "bolt.trianglebadge.exclamationmark.fill")
                            .font(.bitchatSystem(size: 22))
                        Text("High Voltage")
                            .font(.bitchatSystem(size: 13, weight: .semibold))
                    }
                    .foregroundColor(selection == .high ? .white : red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(selection == .high ? red : red.opacity(0.1))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(red.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }

            if selection == .high {
                // Pulsing warning banner
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.bitchatSystem(size: 18))
                        Text("DO NOT APPROACH")
                            .font(.bitchatSystem(size: 15, weight: .bold))
                    }
                    .foregroundColor(red)

                    Text("Keep 25m back \u{00B7} Call 999 and DNO \u{00B7} Wait for engineers")
                        .font(.bitchatSystem(size: 12))
                        .foregroundColor(Color(red: 0.941, green: 0.502, blue: 0.502))
                        .multilineTextAlignment(.center)
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(red.opacity(0.12))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(red.opacity(0.33), lineWidth: 1)
                )
                .opacity(showWarningPulse ? 1.0 : 0.5)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: showWarningPulse)
                .onAppear { showWarningPulse = false }
                .transition(.opacity.combined(with: .offset(y: 8)))

                stepsView(steps: highVoltageSteps)
            }

            if selection == .low {
                stepsView(steps: lowVoltageSteps)
            }
        }
        .padding(.vertical, 8)
    }

    private func stepsView(steps: [String]) -> some View {
        VStack(spacing: 8) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(index + 1)")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(amber)
                        .frame(width: 20, alignment: .trailing)

                    Text(step)
                        .font(.bitchatSystem(size: 13))
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(elevatedBackground)
                .cornerRadius(8)
                .transition(.opacity.combined(with: .offset(y: 8)))
            }
        }
    }
}
#endif
