//
//  5_IntensityPhaseView.swift
//  teamHealth
//
//  Created by Utari Dyani Laksmi on 24/08/25.
//

import SwiftUI

struct IntensityPhaseView: View {
    @Binding var stars: [Star]
    var onFinishedSlides: () -> Void

    // --- Timing (tweak freely) ---
    private let startDelay: Double   = 1.0     // wait before moving
    private let moveDuration: Double = 2.2     // bottom -> top travel time
    private let dwellAtTop: Double   = 1.2     // time to show top text before finishing

    // --- Haptics ---
    @State private var hapticTimer: Timer? = nil
    @State private var lastHapticAt: Date = .distantPast
    private let loopInterval: TimeInterval = 0.50
    private let minGap: TimeInterval = 0.18

    // --- Animation progress ---
    @State private var t: CGFloat = 0          // 0 -> 1 drives position
    @State private var showTopText = false     // switch text at the top

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let cardH = h / 3

            // exact anchors so it’s flush with edges
            let bottomY = h - cardH / 3
            let topY    = cardH / 1.3

            ZStack {
                AmbientDecor(stars: $stars)

                // One moving card (image stays the same; only text swaps at the end)
                
                ZStack {
                    // Image fades in as it moves up
                    Image("area")
                        .resizable()
                        .frame(width: w + 80, height: cardH)
                        .opacity(lerp(0.3, 1.0, t)) // <- only image fades

                    // Text stays full opacity, just swaps at the top
                    if showTopText {
                        Text("The stronger the vibration")
                            .font(.system(size: 17, weight: .regular, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(radius: 4)
                            .fadeInOnAppear(delay: 0.1, duration: 0.8)
                    }
                    else {
                        Text("The higher you move your finger")
                            .font(.system(size: 17, weight: .regular, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(radius: 4)
                    }
                }
                .position(x: w / 2, y: lerp(bottomY, topY, t))
                
//                Image("intensity1")
//                    .resizable()
//                    .frame(width: w + 80, height: cardH)
//                    .overlay(
//                        VStack {
//                            if showTopText {
//                                Text("The stronger the vibration")
//                                    .font(.system(size: 17, weight: .regular, design: .rounded))
//                                    .foregroundColor(.white)
//                                    .shadow(radius: 4)
//                                    .fadeInOnAppear(delay: 0, duration: 0.8)
//                            }
//                            else {
//                                Text("The higher you move your finger")
//                                    .font(.system(size: 17, weight: .regular, design: .rounded))
//                                    .foregroundColor(.white)
//                                    .shadow(radius: 4)
//                            }
//                        }
//                        // make the text swap instantaneous (no fade)
//                        .animation(nil, value: showTopText)
//                    )
//                    // continuous vertical motion bottom -> top
//
//                    .opacity(lerp(0.3, 1.0, t))
            }
            .ignoresSafeArea()
            .onAppear {
                // start a gentle haptic while it travels
                startLoopingHaptic("twilight_50")

                // start motion after a brief delay
                t = 0
                DispatchQueue.main.asyncAfter(deadline: .now() + startDelay) {
                    withAnimation(.easeInOut(duration: moveDuration)) {
                        t = 1
                    }
                }

                // when it reaches the top, swap the text
                DispatchQueue.main.asyncAfter(deadline: .now() + startDelay + moveDuration) {
                    showTopText = true
                    stopLoopingHaptic()
                    startLoopingHaptic("twilight")
                }

                // finish after dwelling at the top
                DispatchQueue.main.asyncAfter(deadline: .now() + startDelay + moveDuration + dwellAtTop + 3) {
                    stopLoopingHaptic()
                    onFinishedSlides()
                }
            }
            .onDisappear {
                stopLoopingHaptic()
            }
        }
    }

    // MARK: - Math
    private func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat {
        a + (b - a) * t
    }

    // MARK: - Haptics
    private func playHaptic(_ name: String, force: Bool = false) {
        let now = Date()
        if !force, now.timeIntervalSince(lastHapticAt) < minGap { return }
        HapticManager.playAHAP(named: name)
        lastHapticAt = now
    }

    private func startLoopingHaptic(_ name: String) {
        stopLoopingHaptic()
        playHaptic(name) // fire immediately
        let timer = Timer(timeInterval: loopInterval, repeats: true) { _ in
            playHaptic(name)
        }
        hapticTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func stopLoopingHaptic(resetThrottle: Bool = false) {
        hapticTimer?.invalidate()
        hapticTimer = nil
        if resetThrottle { lastHapticAt = .distantPast }
    }
}
