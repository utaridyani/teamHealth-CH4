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
    @State private var swap = false

    // timing pls tweak utari
    private let firstDuration: Double = 2.2
    private let pause: Double = 0.3
    private var secondDelay: Double { firstDuration - pause*2.4 }
    private let secondDuration: Double = 2.4
    
    // haptic
    @State private var hapticTimer: Timer? = nil
    @State private var lastHapticAt: Date = .distantPast
    private let loopInterval: TimeInterval = 0.50
    private let minGap: TimeInterval = 0.18

    var body: some View {
        let screenHeight = UIScreen.main.bounds.height
        let screenWidth = UIScreen.main.bounds.width

        ZStack {
            AmbientDecor(stars: $stars)

            ZStack {
                Image("intensity1")
                    .resizable()
                    .frame(width: screenWidth - 20, height: screenHeight / 4)
                Text("The higher you move your finger")
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(radius: 4)
            }
            .opacity(swap ? 0 : 0.7)
            .position(x: screenWidth / 2, y: screenHeight - screenHeight / 5)
            .offset(y: swap ? -(screenHeight * 0.6) : 0)
            .zIndex(2)
            .animation(.easeInOut(duration: firstDuration), value: swap)

            // intensity 2
            ZStack {
                Image("intensity2")
                    .resizable()
                    .frame(width: screenWidth - 20, height: screenHeight / 3.5)
                Text("The stronger the vibration")
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(radius: 4)
            }
            .opacity(swap ? 0.7 : 0)
            .position(x: screenWidth / 2, y: screenHeight / 4.5)
            .offset(y: swap ? 0 : 20)
            .zIndex(1)
            .animation(
                .easeInOut(duration: secondDuration).delay(secondDelay),
                value: swap
            )
        }
        .ignoresSafeArea()
        .onAppear {
            // start looping the first haptic
            startLoopingHaptic("twilight_50")

            // begin swap after a short hold
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                swap = true

                DispatchQueue.main.asyncAfter(deadline: .now() + secondDelay) {
                    // clear throttle
                    stopLoopingHaptic(resetThrottle: true)
                    startLoopingHaptic("twilight")
                }

                let total = secondDelay + secondDuration + 5
                DispatchQueue.main.asyncAfter(deadline: .now() + total) {
                    stopLoopingHaptic() // ensure off
                    onFinishedSlides()
                }
            }
        }
        .onDisappear {
            stopLoopingHaptic()
        }
    }
    
    private func playHaptic(_ name: String, force: Bool = false) {
        let now = Date()
        if !force {
            guard now.timeIntervalSince(lastHapticAt) >= minGap else { return }
        }
        HapticManager.playAHAP(named: name)
        lastHapticAt = now
    }

    private func startLoopingHaptic(_ name: String) {
        stopLoopingHaptic() // clean any previous
        // fire once immediately (throttled)
        playHaptic(name)

        let timer = Timer(timeInterval: loopInterval, repeats: true) { _ in
            playHaptic(name)
        }
        hapticTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func stopLoopingHaptic(resetThrottle: Bool = false) {
        hapticTimer?.invalidate()
        hapticTimer = nil
        if resetThrottle {
            // ensure the very next play isn't blocked by minGap
            lastHapticAt = .distantPast
        }
    }
}
