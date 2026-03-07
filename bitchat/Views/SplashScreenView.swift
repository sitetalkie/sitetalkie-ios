//
// SplashScreenView.swift
// bitchat
//
// This is free and unencumbered software released into the public domain.
// For more information, see <https://unlicense.org>
//

import Foundation
import SwiftUI

struct SplashScreenView: View {
    // Sweep rotation
    @State private var sweepAngle: Double = 0

    // Staggered node ring pulse (one per node, offset by 0.6s)
    @State private var nodeRingOpacity0: Double = 0.22
    @State private var nodeRingOpacity1: Double = 0.22
    @State private var nodeRingOpacity2: Double = 0.22
    @State private var nodeRingOpacity3: Double = 0.22

    // Subtitle + loading bar
    @State private var subtitleOpacity: Double = 0.4
    @State private var loadingBarOffset: CGFloat = -32

    // Colours
    private let bgTop = Color(red: 0.078, green: 0.082, blue: 0.059)       // #14150F
    private let bgBottom = Color(red: 0.035, green: 0.035, blue: 0.043)    // #09090B
    private let amber = Color(red: 0.910, green: 0.588, blue: 0.047)       // #E8960C
    private let gold = Color(red: 0.961, green: 0.651, blue: 0.137)        // #F5A623
    private let subtitleColor = Color(red: 0.541, green: 0.525, blue: 0.447) // #8a8672

    // Radar is drawn in a 200×200 coordinate space
    private let radarSize: CGFloat = 200

    // Node positions (matching the SVG exactly)
    private let nodes: [(x: CGFloat, y: CGFloat, outerR: CGFloat, midR: CGFloat, innerR: CGFloat)] = [
        (140, 40,  18, 12, 5),
        (55,  68,  20, 14, 5.5),
        (145, 132, 20, 14, 5.5),
        (60,  160, 18, 12, 5),
    ]

    var body: some View {
        ZStack {
            LinearGradient(colors: [bgTop, bgBottom], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Radar graphic
                ZStack {
                    radarBackground
                    radarSweep
                    crossMeshLines
                    sCurveGlow
                    sCurveMain
                    nodeDotsView
                }
                .frame(width: radarSize, height: radarSize)

                // Text below radar
                VStack(spacing: 8) {
                    Text("SiteTalkie")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(gold)

                    Text("Scanning for nearby users")
                        .font(.system(size: 11))
                        .foregroundColor(subtitleColor)
                        .opacity(subtitleOpacity)

                    // Loading bar: 80×3, background rgba(232,150,12,0.1), 40% width fill
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(amber.opacity(0.1))
                            .frame(width: 80, height: 3)

                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(amber)
                            .frame(width: 32, height: 3)
                            .offset(x: loadingBarOffset)
                    }
                    .frame(width: 80, height: 3)
                    .clipped()
                    .padding(.top, 4)
                }
            }
        }
        .onAppear { startAnimations() }
    }

    // MARK: - Animations

    private func startAnimations() {
        // Radar sweep: 360° every 2.5s
        withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
            sweepAngle = 360
        }

        // Staggered node ring pulse, each offset 0.6s, period 2.5s
        let pulseDuration: Double = 2.5
        let offsets: [Double] = [0, 0.6, 1.2, 1.8]
        let bindings = [
            $nodeRingOpacity0, $nodeRingOpacity1,
            $nodeRingOpacity2, $nodeRingOpacity3,
        ]
        for i in 0..<4 {
            DispatchQueue.main.asyncAfter(deadline: .now() + offsets[i]) {
                withAnimation(.easeInOut(duration: pulseDuration).repeatForever(autoreverses: true)) {
                    bindings[i].wrappedValue = 0.32
                }
            }
        }

        // Subtitle opacity pulse 0.4–0.8 over 1.5s
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            subtitleOpacity = 0.8
        }

        // Loading bar slides left→right every 1.8s
        withAnimation(.linear(duration: 1.8).repeatForever(autoreverses: false)) {
            loadingBarOffset = 80
        }
    }

    // MARK: - Radar Background

    private var radarBackground: some View {
        ZStack {
            // Three concentric circles: r=30, r=58, r=86
            Circle()
                .stroke(amber.opacity(0.1), lineWidth: 0.6)
                .frame(width: 60, height: 60)
            Circle()
                .stroke(amber.opacity(0.075), lineWidth: 0.6)
                .frame(width: 116, height: 116)
            Circle()
                .stroke(amber.opacity(0.055), lineWidth: 0.6)
                .frame(width: 172, height: 172)

            // Diagonal crosshairs corner-to-corner
            Path { p in
                p.move(to: CGPoint(x: 0, y: 0))
                p.addLine(to: CGPoint(x: radarSize, y: radarSize))
            }
            .stroke(amber.opacity(0.055), lineWidth: 0.35)

            Path { p in
                p.move(to: CGPoint(x: radarSize, y: 0))
                p.addLine(to: CGPoint(x: 0, y: radarSize))
            }
            .stroke(amber.opacity(0.055), lineWidth: 0.35)

            // Center dot r=2.5
            Circle()
                .fill(amber.opacity(0.25))
                .frame(width: 5, height: 5)
        }
    }

    // MARK: - Radar Sweep (30° pie + leading line)

    private var radarSweep: some View {
        ZStack {
            // Pie slice: 30° arc, fill #E8960C 0.08
            SweepSlice(angleDegrees: 30)
                .fill(amber.opacity(0.08))

            // Leading edge line
            SweepLeadingLine(angleDegrees: 30)
                .stroke(gold.opacity(0.15), lineWidth: 1)
        }
        .frame(width: radarSize, height: radarSize)
        .rotationEffect(.degrees(sweepAngle))
    }

    // MARK: - Cross-Mesh Lines

    private var crossMeshLines: some View {
        ZStack {
            // Adjacent node connections (opacity 0.07, width 2)
            line(from: nodes[0], to: nodes[2], width: 2, opacity: 0.07)
            line(from: nodes[1], to: nodes[3], width: 2, opacity: 0.07)
            // Diagonal node connections (opacity 0.04, width 1.5)
            line(from: nodes[0], to: nodes[3], width: 1.5, opacity: 0.04)
            line(from: nodes[1], to: nodes[2], width: 1.5, opacity: 0.04)
        }
        .frame(width: radarSize, height: radarSize)
    }

    private func line(
        from a: (x: CGFloat, y: CGFloat, outerR: CGFloat, midR: CGFloat, innerR: CGFloat),
        to b: (x: CGFloat, y: CGFloat, outerR: CGFloat, midR: CGFloat, innerR: CGFloat),
        width: CGFloat, opacity: Double
    ) -> some View {
        Path { p in
            p.move(to: CGPoint(x: a.x, y: a.y))
            p.addLine(to: CGPoint(x: b.x, y: b.y))
        }
        .stroke(gold.opacity(opacity), lineWidth: width)
    }

    // MARK: - S Curve (two passes: glow + main)

    private var sCurveGlow: some View {
        SCurvePath()
            .stroke(gold.opacity(0.06), style: StrokeStyle(lineWidth: 14, lineCap: .round))
            .frame(width: radarSize, height: radarSize)
    }

    private var sCurveMain: some View {
        SCurvePath()
            .stroke(gold.opacity(0.28), style: StrokeStyle(lineWidth: 8, lineCap: .round))
            .frame(width: radarSize, height: radarSize)
    }

    // MARK: - Node Dots

    private var nodeDotsView: some View {
        let opacities = [nodeRingOpacity0, nodeRingOpacity1, nodeRingOpacity2, nodeRingOpacity3]
        return ZStack {
            ForEach(0..<nodes.count, id: \.self) { i in
                let n = nodes[i]
                let x = n.x - radarSize / 2
                let y = n.y - radarSize / 2

                // Outer pulsing ring
                Circle()
                    .stroke(amber, lineWidth: 1.8)
                    .opacity(opacities[i])
                    .frame(width: n.outerR * 2, height: n.outerR * 2)
                    .offset(x: x, y: y)

                // Middle fill circle
                Circle()
                    .fill(amber)
                    .frame(width: n.midR * 2, height: n.midR * 2)
                    .offset(x: x, y: y)

                // Inner bright dot
                Circle()
                    .fill(gold)
                    .frame(width: n.innerR * 2, height: n.innerR * 2)
                    .offset(x: x, y: y)
            }
        }
    }
}

// MARK: - Shapes

/// 30° pie slice from center, starting at 12-o'clock
private struct SweepSlice: Shape {
    let angleDegrees: Double

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        var p = Path()
        p.move(to: center)
        p.addArc(center: center, radius: radius,
                 startAngle: .degrees(-90),
                 endAngle: .degrees(-90 + angleDegrees),
                 clockwise: false)
        p.closeSubpath()
        return p
    }
}

/// Line from center to the leading edge of the sweep
private struct SweepLeadingLine: Shape {
    let angleDegrees: Double

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let angle = Angle.degrees(-90 + angleDegrees)
        let edge = CGPoint(
            x: center.x + radius * Foundation.cos(angle.radians),
            y: center.y + radius * Foundation.sin(angle.radians)
        )
        var p = Path()
        p.move(to: center)
        p.addLine(to: edge)
        return p
    }
}

/// The "S" bezier matching the SVG exactly
private struct SCurvePath: Shape {
    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 200
        let sy = rect.height / 200
        var p = Path()
        p.move(to: CGPoint(x: 140 * sx, y: 40 * sy))
        p.addCurve(to: CGPoint(x: 55 * sx, y: 68 * sy),
                    control1: CGPoint(x: 140 * sx, y: 40 * sy),
                    control2: CGPoint(x: 55 * sx, y: 20 * sy))
        p.addCurve(to: CGPoint(x: 145 * sx, y: 132 * sy),
                    control1: CGPoint(x: 55 * sx, y: 105 * sy),
                    control2: CGPoint(x: 145 * sx, y: 95 * sy))
        p.addCurve(to: CGPoint(x: 60 * sx, y: 160 * sy),
                    control1: CGPoint(x: 145 * sx, y: 180 * sy),
                    control2: CGPoint(x: 60 * sx, y: 160 * sy))
        return p
    }
}
