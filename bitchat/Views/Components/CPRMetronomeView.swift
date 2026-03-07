import SwiftUI
import AudioToolbox

#if os(iOS)
struct CPRMetronomeView: View {
    enum Phase {
        case compress
        case breathe
    }

    @State private var isRunning = false
    @State private var phase: Phase = .compress
    @State private var count: Int = 1
    @State private var cyclesComplete: Int = 0
    @State private var timer: Timer?
    @State private var beatScale: CGFloat = 1.0
    @State private var emitRingScale: CGFloat = 1.0
    @State private var emitRingOpacity: Double = 0

    private let orbSize: CGFloat = 130
    private let interval: TimeInterval = 0.545 // 110 BPM

    private let amber = Color(red: 0.910, green: 0.588, blue: 0.047)
    private let green = Color(red: 0.204, green: 0.780, blue: 0.349)
    private let elevatedBackground = Color(red: 0.141, green: 0.149, blue: 0.157)
    private let secondaryText = Color(red: 0.541, green: 0.557, blue: 0.588)
    private let tertiaryText = Color(red: 0.353, green: 0.369, blue: 0.400)

    private var orbColor: Color {
        if !isRunning { return elevatedBackground }
        return phase == .compress ? amber : green
    }

    private var phaseMax: Int {
        phase == .compress ? 30 : 2
    }

    private var progress: CGFloat {
        CGFloat(count) / CGFloat(phaseMax)
    }

    var body: some View {
        VStack(spacing: 20) {
            // Orb
            ZStack {
                // Emit ring (compression beats only)
                if isRunning && phase == .compress {
                    Circle()
                        .stroke(amber.opacity(0.3), lineWidth: 2)
                        .frame(width: orbSize, height: orbSize)
                        .scaleEffect(emitRingScale)
                        .opacity(emitRingOpacity)
                }

                // Progress ring
                Circle()
                    .stroke(elevatedBackground, lineWidth: 4)
                    .frame(width: orbSize + 16, height: orbSize + 16)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(orbColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: orbSize + 16, height: orbSize + 16)
                    .rotationEffect(.degrees(-90))

                // Main orb
                Circle()
                    .fill(orbColor)
                    .frame(width: orbSize, height: orbSize)
                    .scaleEffect(beatScale)

                // Content
                if !isRunning {
                    Text("Tap to start")
                        .font(.bitchatSystem(size: 13))
                        .foregroundColor(tertiaryText)
                } else {
                    VStack(spacing: 2) {
                        Text("\(count)")
                            .font(.system(size: 40, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                        Text("of \(phaseMax)")
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(.black.opacity(0.6))
                    }
                }
            }
            .frame(width: orbSize + 24, height: orbSize + 24)
            .contentShape(Circle())
            .onTapGesture {
                if isRunning { stopMetronome() } else { startMetronome() }
            }

            // Phase card
            if isRunning {
                VStack(spacing: 6) {
                    if phase == .compress {
                        Text("Push hard. Push fast.")
                            .font(.bitchatSystem(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        Text("5\u{2013}6 cm depth \u{00B7} full chest recoil")
                            .font(.bitchatSystem(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                    } else {
                        Text("Tilt head. Pinch nose. 2 breaths.")
                            .font(.bitchatSystem(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                        Text("Watch chest rise \u{00B7} 1 second each")
                            .font(.bitchatSystem(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(
                    (phase == .compress ? amber : green).opacity(0.12)
                )
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke((phase == .compress ? amber : green).opacity(0.2), lineWidth: 1)
                )
            }

            // Stats
            HStack(spacing: 20) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.bitchatSystem(size: 11))
                        .foregroundColor(tertiaryText)
                    Text("\(cyclesComplete) cycles")
                        .font(.bitchatSystem(size: 11))
                        .foregroundColor(secondaryText)
                }

                Text("110 BPM")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(secondaryText)

                Button(action: resetMetronome) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.bitchatSystem(size: 11))
                        Text("Reset")
                            .font(.bitchatSystem(size: 11, weight: .medium))
                    }
                    .foregroundColor(tertiaryText)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 16)
        .onDisappear {
            timer?.invalidate()
        }
    }

    private func startMetronome() {
        isRunning = true
        phase = .compress
        count = 1
        playBeat()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            advanceBeat()
        }
    }

    private func stopMetronome() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    private func resetMetronome() {
        stopMetronome()
        phase = .compress
        count = 1
        cyclesComplete = 0
        beatScale = 1.0
    }

    private func advanceBeat() {
        if count >= phaseMax {
            if phase == .compress {
                phase = .breathe
                count = 1
            } else {
                phase = .compress
                count = 1
                cyclesComplete += 1
            }
        } else {
            count += 1
        }
        playBeat()
    }

    private func playBeat() {
        if phase == .compress {
            AudioServicesPlaySystemSound(1104)
            // Pulse animation
            withAnimation(.easeOut(duration: 0.1)) { beatScale = 1.08 }
            withAnimation(.easeIn(duration: 0.3).delay(0.1)) { beatScale = 1.0 }
            // Emit ring
            emitRingScale = 1.0
            emitRingOpacity = 0.6
            withAnimation(.easeOut(duration: 0.4)) {
                emitRingScale = 1.5
                emitRingOpacity = 0
            }
        } else {
            AudioServicesPlaySystemSound(1057)
            // Gentle breathing animation
            withAnimation(.easeInOut(duration: 0.8)) { beatScale = 1.05 }
            withAnimation(.easeInOut(duration: 0.8).delay(0.8)) { beatScale = 1.0 }
        }
    }
}
#endif
