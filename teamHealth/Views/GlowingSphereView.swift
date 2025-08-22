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
    
    @State private var pulseAnimation = false
    @State private var rotationAngle: Double = 0
    @State private var internalBreathingPhase: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Outer glow rings
            if isActive {
                ForEach(0..<3, id: \.self) { ring in
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    sphereType.baseColor.opacity(0.6 - Double(ring) * 0.2),
                                    sphereType.baseColor.opacity(0.4 - Double(ring) * 0.15),
                                    sphereType.baseColor.opacity(0.3 - Double(ring) * 0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 280 + CGFloat(ring * 30), height: 280 + CGFloat(ring * 30))
                        .opacity(pulseAnimation ? 0.8 - Double(ring) * 0.2 : 0.3 - Double(ring) * 0.1)
                        .scaleEffect(pulseAnimation ? 1.1 : 0.95)
                        .rotationEffect(.degrees(rotationAngle + Double(ring * 30)))
                }
            }
            
            // Main sphere with bouncy breathing
            ZStack {
                // Base sphere with gradient
                Circle()
                    .fill(
                        RadialGradient(
                            colors: sphereType.gradientColors,
                            center: UnitPoint(x: 0.35, y: 0.25),
                            startRadius: 20,
                            endRadius: 120
                        )
                    )
                
                // Anime-style highlight
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.9),
                                Color.white.opacity(0.3),
                                Color.clear
                            ],
                            center: UnitPoint(x: 0.3, y: 0.2),
                            startRadius: 10,
                            endRadius: 50
                        )
                    )
                
                // Bottom shadow for depth
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.clear,
                                Color.black.opacity(0.1),
                                Color.black.opacity(0.2)
                            ],
                            center: UnitPoint(x: 0.5, y: 0.8),
                            startRadius: 40,
                            endRadius: 100
                        )
                    )
            }
            .frame(width: 220, height: 220)
            .scaleEffect(scale * (1.0 + sin(useCustomBreathing ? breathingPhase : internalBreathingPhase) * (useCustomBreathing ? 0.12 : 0.06)))
            
            // Outer glow effect
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            sphereType.baseColor.opacity(0.6),
                            sphereType.baseColor.opacity(0.3),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 60,
                        endRadius: 130
                    )
                )
                .frame(width: 260, height: 260)
                .scaleEffect(scale * (1.0 + sin(useCustomBreathing ? breathingPhase : internalBreathingPhase) * (useCustomBreathing ? 0.08 : 0.04)))
                .opacity(glowIntensity)
                .blur(radius: 10)
        }
        .shadow(color: sphereType.baseColor.opacity(0.5), radius: 30, x: 0, y: 0)
        .shadow(color: sphereType.baseColor.opacity(0.3), radius: 15, x: 0, y: 0)
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
        .onReceive(Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()) { _ in
            if !useCustomBreathing {
                internalBreathingPhase += 0.025
            }
        }
    }
    
    private func startAnimations() {
        // Pulse animation
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            pulseAnimation.toggle()
        }
        
        // Slow rotation for outer rings
        withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
        
        // Glow breathing
        withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
            glowIntensity = glowIntensity == AnimationConstants.sphereGlowIntensity ? 1.0 : AnimationConstants.sphereGlowIntensity
        }
    }
}

// MARK: - Sphere Label View
struct SphereLabelView: View {
    let sphereType: SphereType
    let isExpanded: Bool
    
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
                Text("Long press to select")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
}
