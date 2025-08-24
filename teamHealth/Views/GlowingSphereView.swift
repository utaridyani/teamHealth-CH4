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
        // This logic now correctly chooses between the two parent-controlled phases
        let currentBreathingPhase = useCustomBreathing ? breathingPhase : idleBreathingPhase
        let finalScale = (1.0 + sin(currentBreathingPhase) * 0.08)
        
        ZStack {
            // MARK: - Refined Bubble Sphere Design
            
            // 1. Dimmed Atmospheric Halo
            Circle()
                .fill(baseColor)
                .frame(width: 230, height: 230)
                .blur(radius: 40)
                .opacity(isActive ? glowIntensity * 0.4 : 0.2)
            
            // Main sphere body and its harmonious reflections
            ZStack {
                // 2. Core Transparent Bubble
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                baseColor.opacity(0.25),
                                baseColor.opacity(0.1),
                                baseColor.opacity(0.2)
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 100
                        )
                    )
                
                // 3. Main Glossy Reflection (top-left) - More natural gradient
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
                
                // 4. Softer, Wider Highlight - Adds to the harmony
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
                
                // 5. Subtle Inner Light Source (bottom-right) - Gives volume
                Circle()
                    .fill(baseColor.opacity(0.4))
                    .frame(width: 120, height: 120)
                    .offset(x: 40, y: 40)
                    .blur(radius: 40)
                
                // 6. Rim Highlight for a glassy edge
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
            }
            .frame(width: 200, height: 200)
            .clipShape(Circle())
            .scaleEffect(finalScale * scale) // Apply combined scaling
            .shadow(color: baseColor.opacity(0.3), radius: 20, x: 0, y: 0)
            .shadow(color: Color.white.opacity(0.15), radius: 8, x: 0, y: 0)
        }
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
