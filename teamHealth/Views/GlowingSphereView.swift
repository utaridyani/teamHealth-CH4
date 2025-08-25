//
//  GlowingSphereView.swift
//  teamHealth
//
//  Created by Zap on 21/08/25.
//

import SwiftUI

struct GlowingSphereView: View {
    // Parameters from MainMenuView
    let sphereType: SphereType
    let isActive: Bool
    @Binding var scale: CGFloat
    @Binding var glowIntensity: Double
    var breathingPhase: CGFloat = 0
    var idleBreathingPhase: CGFloat = 0 // New property for idle animation
    var useCustomBreathing: Bool = false
    
    // Internal state for the sphere's own animations
    @State private var pulseAnimation = false
    
    var body: some View {
        let baseColor = sphereType.baseColor
        // Create complementary colors based on the base color
        let primaryGlow = baseColor
        let secondaryGlow = baseColor.opacity(0.7)
        let tertiaryGlow = Color.white.opacity(0.8)
        
        // This logic now correctly chooses between the two parent-controlled phases
        let currentBreathingPhase = useCustomBreathing ? breathingPhase : idleBreathingPhase
        let finalScale = (1.0 + sin(currentBreathingPhase) * 0.08)
        
        ZStack {
            // MARK: - Anime-Style Sphere Design (Updated with dynamic colors)
            
            // Subtle outer glow (only for active spheres)
            if isActive {
                ForEach(0..<2, id: \.self) { ring in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    primaryGlow.opacity(0.05 - Double(ring) * 0.08),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 120 + CGFloat(ring * 40),
                                endRadius: 180 + CGFloat(ring * 60)
                            )
                        )
                        .frame(width: 300 + CGFloat(ring * 50), height: 300 + CGFloat(ring * 50))
                        .opacity(pulseAnimation ? 0.6 - Double(ring) * 0.2 : 0.2 - Double(ring) * 0.1)
                        .scaleEffect(pulseAnimation ? 1.05 : 0.98)
                }
            }
            
            // Main circle with anime-style shading - updated gradient
            ZStack {
                // Base circle with vibrant gradient using baseColor
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white,
                                tertiaryGlow,
                                primaryGlow.opacity(0.9),
                                baseColor.opacity(0.8)
                            ],
                            center: UnitPoint(x: 0.35, y: 0.25),
                            startRadius: 15,
                            endRadius: 100
                        )
                    )
                
                // Anime highlight
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.9),
                                Color.white.opacity(0.3),
                                Color.clear
                            ],
                            center: UnitPoint(x: 0.3, y: 0.2),
                            startRadius: 8,
                            endRadius: 45
                        )
                    )
            }
            .frame(width: 200, height: 200)
            .scaleEffect(finalScale * scale)
            
            // Inner glow effect - now using baseColor variations
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            primaryGlow.opacity(isActive ? 0.5 : 0.2),
                            secondaryGlow.opacity(isActive ? 0.3 : 0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 60,
                        endRadius: 90
                    )
                )
                .frame(width: 220, height: 220)
                .scaleEffect(finalScale * scale)
                .opacity(isActive ? glowIntensity : 0.9)
            
            // Sparkle effects (only when active) - updated with baseColor
//            if isActive {
//                ForEach(0..<8, id: \.self) { sparkle in
//                    Image(systemName: "sparkles")
//                        .font(.system(size: 16, weight: .bold))
//                        .foregroundStyle(
//                            LinearGradient(
//                                colors: [.white, primaryGlow, baseColor],
//                                startPoint: .topLeading,
//                                endPoint: .bottomTrailing
//                            )
//                        )
//                        .scaleEffect(pulseAnimation ? 1.2 : 0.8)
//                        .opacity(pulseAnimation ? 0.9 : 0.5)
//                        .offset(
//                            x: cos(Double(sparkle) * .pi / 4) * 140,
//                            y: sin(Double(sparkle) * .pi / 4) * 140
//                        )
//                }
//            }
        }
        .shadow(color: primaryGlow.opacity(0.7), radius: 25, x: 0, y: 0)
        .shadow(color: baseColor.opacity(0.5), radius: 12, x: 0, y: 0)
        .onAppear {
            if isActive {
                startAnimations()
            }
        }
        .onChange(of: isActive) { newValue in
            if newValue {
                startAnimations()
            }
        }
    }
    
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            pulseAnimation.toggle()
        }
        
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
    
    private let displayDuration: TimeInterval = 3.0
    private let fadeDuration: TimeInterval = 1.2
    
    var body: some View {
        VStack(spacing: 24) {
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
                    ForEach(0..<instructionTexts.count, id: \.self) { index in
                        Text(instructionTexts[index])
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                            .opacity(currentTextIndex == index ? textOpacity : 0)
                    }
                }
                .onAppear(perform: startTextCycling)
                .onDisappear {
                    timer?.invalidate()
                    timer = nil
                }
            }
        }
    }
    
    private func startTextCycling() {
        textOpacity = 1.0
        timer = Timer.scheduledTimer(withTimeInterval: displayDuration, repeats: true) { _ in
            cycleText()
        }
    }
    
    private func cycleText() {
        withAnimation(.easeOut(duration: fadeDuration)) {
            textOpacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + fadeDuration) {
            currentTextIndex = (currentTextIndex + 1) % instructionTexts.count
            withAnimation(.easeIn(duration: fadeDuration)) {
                textOpacity = 1.0
            }
        }
    }
}
