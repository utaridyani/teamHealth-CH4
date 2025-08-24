//
//  GlowingSphereView.swift
//  teamHealth
//
//  Created by Zap on 21/08/25.
//

import SwiftUI

struct GlowingSphereView: View {
    let sphereType: SphereType
    let isActive: Bool
    @Binding var scale: CGFloat
    @Binding var glowIntensity: Double
    var breathingPhase: CGFloat = 0
    var useCustomBreathing: Bool = false
    
    // State for the sphere's natural breathing animation
    @State private var internalBreathingPhase: CGFloat = 0
    
    var body: some View {
        ZStack {
            let baseColor = sphereType.baseColor
            
            // 1. Soft Outer Glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [baseColor.opacity(0.4), .clear],
                        center: .center,
                        startRadius: 80, // Start glow further out
                        endRadius: 180
                    )
                )
                .frame(width: 360, height: 360)
                .blur(radius: 25)
                .opacity(isActive ? glowIntensity * 0.8 : 0.5)
                .scaleEffect(useCustomBreathing ? (1.0 + sin(breathingPhase) * 0.05) : (1.0 + sin(internalBreathingPhase) * 0.03))
            
            // 2. Main Bubble Body
            ZStack {
                // Core transparent body
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                baseColor.opacity(0.25),
                                baseColor.opacity(0.1),
                                baseColor.opacity(0.2) // Slightly darker edge
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                
                // Rim Highlight for a glassy edge
                Circle()
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                .white.opacity(0.6),
                                baseColor.opacity(0.1),
                                .white.opacity(0.5)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2.0
                    )
                    .blur(radius: 1)
                
                // Main glossy reflection (top-left)
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [.white.opacity(0.9), .white.opacity(0.0)]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 45
                        )
                    )
                    .frame(width: 90, height: 90)
                    .offset(x: -45, y: -50)
                    .blur(radius: 2)
                
                // Softer, wider highlight
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [.white.opacity(0.4), .white.opacity(0.0)]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .offset(x: -30, y: -40)
                    .blur(radius: 5)
                    .opacity(0.8)
                
                // Subtle inner light source (bottom-right)
                Circle()
                    .fill(baseColor.opacity(0.4))
                    .frame(width: 120, height: 120)
                    .offset(x: 40, y: 40)
                    .blur(radius: 40)
            }
            .frame(width: 200, height: 200)
            .clipShape(Circle()) // This is the fix! It constrains the highlights.
            // Apply breathing effect to the entire bubble structure
            .scaleEffect(useCustomBreathing ? (1.0 + sin(breathingPhase) * 0.05) : (1.0 + sin(internalBreathingPhase) * 0.03))
        }
        .onAppear {
            startAnimations()
        }
        .onChange(of: isActive) { newValue in
            if newValue {
                startAnimations()
            }
        }
        .onReceive(Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()) { _ in
            // Drive the natural breathing animation if not controlled externally
            if !useCustomBreathing {
                internalBreathingPhase += 0.02
            }
        }
    }
    
    private func startAnimations() {
        // Simplified animation for the glow intensity
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            glowIntensity = glowIntensity == AnimationConstants.sphereGlowIntensity ? 1.0 : AnimationConstants.sphereGlowIntensity
        }
    }
}

// MARK: - Sphere Label View
struct SphereLabelView: View {
    let sphereType: SphereType
    let isExpanded: Bool
    
    @State private var currentTextIndex = 0
    @State private var textOpacity: Double = 1.0
    @State private var timer: Timer?
    
    private let instructionTexts = [
        "Tap to preview the vibration",
        "Long press to open the vibration space"
    ]
    
    private let displayDuration: TimeInterval = 3.0 // How long each text is visible
    private let fadeDuration: TimeInterval = 1.2 // How long the fade transition takes
    
    var body: some View {
        VStack(spacing: 10) {
            Text(sphereType.name)
                .font(.system(size: 32, weight: .semibold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, sphereType.baseColor.opacity(0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: sphereType.baseColor.opacity(0.5), radius: 5, x: 0, y: 2)
            
            if !isExpanded {
                ZStack {
                    // Both texts layered, with opacity controlling visibility
                    ForEach(0..<instructionTexts.count, id: \.self) { index in
                        Text(instructionTexts[index])
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                            .opacity(currentTextIndex == index ? textOpacity : 0)
                    }
                }
                .onAppear {
                    startTextCycling()
                }
                .onDisappear {
                    timer?.invalidate()
                    timer = nil
                }
            }
        }
    }
    
    private func startTextCycling() {
        // Initial display
        textOpacity = 1.0
        
        // Start the cycling timer
        timer = Timer.scheduledTimer(withTimeInterval: displayDuration, repeats: true) { _ in
            cycleText()
        }
    }
    
    private func cycleText() {
        // Fade out current text
        withAnimation(.easeOut(duration: fadeDuration)) {
            textOpacity = 0
        }
        
        // Wait for fade out, then switch text and fade in
        DispatchQueue.main.asyncAfter(deadline: .now() + fadeDuration) {
            currentTextIndex = (currentTextIndex + 1) % instructionTexts.count
            
            withAnimation(.easeIn(duration: fadeDuration)) {
                textOpacity = 1.0
            }
        }
    }
}
