import SwiftUI

#if os(iOS)
struct CountdownTimerView: View {
    let totalSeconds: Int
    let label: String
    let accentColor: Color
    let note: String

    @State private var remaining: Int
    @State private var isRunning = false
    @State private var timer: Timer?

    private let backgroundColor = Color(red: 0.055, green: 0.063, blue: 0.071)
    private let cardBackground = Color(red: 0.102, green: 0.110, blue: 0.125)
    private let elevatedBackground = Color(red: 0.141, green: 0.149, blue: 0.157)
    private let secondaryText = Color(red: 0.541, green: 0.557, blue: 0.588)
    private let tertiaryText = Color(red: 0.353, green: 0.369, blue: 0.400)
    private let amber = Color(red: 0.910, green: 0.588, blue: 0.047)
    private let green = Color(red: 0.204, green: 0.780, blue: 0.349)

    init(totalSeconds: Int, label: String, accentColor: Color, note: String) {
        self.totalSeconds = totalSeconds
        self.label = label
        self.accentColor = accentColor
        self.note = note
        _remaining = State(initialValue: totalSeconds)
    }

    private var progress: CGFloat {
        guard totalSeconds > 0 else { return 0 }
        return CGFloat(totalSeconds - remaining) / CGFloat(totalSeconds)
    }

    private var ringColor: Color {
        if remaining == 0 { return green }
        if remaining < 60 { return amber }
        return accentColor
    }

    private var timeString: String {
        let mins = remaining / 60
        let secs = remaining % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    var body: some View {
        VStack(spacing: 20) {
            Text(label.uppercased())
                .font(.bitchatSystem(size: 9, weight: .medium, design: .monospaced))
                .foregroundColor(tertiaryText)
                .kerning(1.2)

            ZStack {
                // Background ring
                Circle()
                    .stroke(elevatedBackground, lineWidth: 6)
                    .frame(width: 160, height: 160)

                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(ringColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)

                // Time or complete
                if remaining == 0 {
                    VStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.bitchatSystem(size: 28))
                            .foregroundColor(green)
                        Text("Complete")
                            .font(.bitchatSystem(size: 15, weight: .semibold))
                            .foregroundColor(green)
                    }
                } else {
                    Text(timeString)
                        .font(.system(size: 38, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                }
            }

            // Controls
            HStack(spacing: 16) {
                Button(action: toggleTimer) {
                    HStack(spacing: 6) {
                        Image(systemName: isRunning ? "pause.fill" : "play.fill")
                            .font(.bitchatSystem(size: 14))
                        Text(isRunning ? "Pause" : "Start")
                            .font(.bitchatSystem(size: 14, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(accentColor.opacity(0.2))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(accentColor.opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                Button(action: resetTimer) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.bitchatSystem(size: 14))
                        Text("Reset")
                            .font(.bitchatSystem(size: 14, weight: .medium))
                    }
                    .foregroundColor(secondaryText)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(elevatedBackground)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }

            // Note
            Text(note)
                .font(.bitchatSystem(size: 11))
                .foregroundColor(secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .padding(.vertical, 20)
        .onDisappear {
            timer?.invalidate()
        }
    }

    private func toggleTimer() {
        if isRunning {
            timer?.invalidate()
            timer = nil
            isRunning = false
        } else {
            guard remaining > 0 else { return }
            isRunning = true
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                if remaining > 0 {
                    remaining -= 1
                } else {
                    timer?.invalidate()
                    timer = nil
                    isRunning = false
                }
            }
        }
    }

    private func resetTimer() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        remaining = totalSeconds
    }
}
#endif
