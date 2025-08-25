//
//  GuidePhaseView.swift
//  test_haptics
//
//  Created by Utari Dyani Laksmi on 24/08/25.
//

import SwiftUI

struct GuidePhaseView: View {
    @Binding var stars: [Star]
    let sphereType: SphereType
    @Binding var step: Int
    @Binding var didLongPress: Bool
    @State private var showBurst = false
    @State private var text2 = false
    var onFinishedSlides: () -> Void

    @State private var sphereScale: CGFloat = 1.0
    @State private var sphereGlowIntensity: Double = AnimationConstants.sphereGlowIntensity
    
    @State private var exploded = false
    @State private var explodeScale: CGFloat = 1.0
    @State private var explodeOpacity: Double = 1.0
    @State private var explodeBlur: CGFloat = 0

    var body: some View {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height

        let centerWidth = screenWidth / 2
        let centerHeight = screenHeight / 2
        
        
        ZStack {
            AmbientDecor(stars: $stars)
            VStack(spacing: 0) {
                if !showBurst {
                    Text("Long press the Twilight to\nopen the vibration space")
                        .font(.system(size: 17, weight: .regular, design: .rounded))
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(
                          LinearGradient(
                            colors: [Color.white, Color.white.opacity(0.5)],
                            startPoint: .top,
                            endPoint: .bottom
                          )
                        )
                        .transition(.opacity)   // fade out
                        .animation(.easeOut(duration: 0.3), value: showBurst)
                }
                
                ZStack {
                    ZStack {
                        RescaledSphere(
                            sphereType: sphereType,
                            isActive: true,
                            targetWidth: centerWidth,
                            targetHeight: centerHeight
                        )
                        RescaledSphere(
                            sphereType: sphereType,
                            isActive: true,
                            targetWidth: centerWidth,
                            targetHeight: centerHeight
                        )
                    }
                    .frame(width: centerWidth, height: centerHeight)
                    .scaleEffect(explodeScale)
                    .opacity(explodeOpacity)
                    .blur(radius: explodeBlur)
                    .animation(.easeOut(duration: 0.55), value: explodeScale)
                    .animation(.easeOut(duration: 0.55), value: explodeOpacity)
                    .animation(.easeOut(duration: 0.55), value: explodeBlur)
                    .gesture(
                        LongPressGesture(minimumDuration: 1.0)
                            .onChanged { _ in
                                // Give it a little “press” feedback
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                    sphereScale = 0.92
                                    sphereGlowIntensity = 1.25
                                }
                            }
                            .onEnded { _ in
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    didLongPress = true
                                    step += 1
                                    sphereScale = 1.0
                                    sphereGlowIntensity = AnimationConstants.sphereGlowIntensity
                                }
                                showBurst = true
                                exploded = true
                                explodeScale = 4    // how “big” the blowout feels
                                explodeOpacity = 0.0   // vanish as it explodes
                                explodeBlur = 18       // soft blur as it expands
                            }
                    )

                    // Burst radiates from the same center as the sphere
                    if showBurst {
                        SpectrumBurst(
                            baseColor: sphereType.baseColor,
                            duration: 2.0,
                            maxScale: 8,
                            repeatWaves: 5
                        )
                        .allowsHitTesting(false)
                    }
                    
                    if exploded {
                        ExplodeEffect(baseColor: sphereType.baseColor, shardCount: 26)
                            .allowsHitTesting(false)
                    }
                }
                .padding(.top, -50)

                if !showBurst {
                    Text("Twilight")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .overlay(
                            LinearGradient(
                                colors: [Color.white.opacity(1.0), Color.white.opacity(0.7)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .mask(
                            Text("Twilight")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                        )
                        .padding(.top, -60)
                        .transition(.opacity)
                        .animation(.easeOut(duration: 0.3), value: showBurst)
                }
            }
            .frame(alignment: .center)
            .ignoresSafeArea()
            .navigationBarBackButtonHidden()
            .onChange(of: showBurst) { _, newValue in
                if newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        onFinishedSlides()
                    }
                }
            }
        }
    }
    
    private func sphereType(for theme: MainTutorialView.Theme) -> SphereType {
        switch theme.name.lowercased() {
        case "dawn":     return .dawn
        case "twilight": return .twilight
        case "reverie":  return .reverie
        default:         return .dawn
        }
    }
}

// Spectrum after long press
struct SpectrumBurst: View {
    var baseColor: Color = .blue
    var duration: Double = 1.6
    var maxScale: CGFloat = 6.0
    var repeatWaves: Int = 3

    @State private var t: CGFloat = 0.0

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [
                    baseColor.opacity(0.00),
                    baseColor.opacity(0.55),
                    baseColor.opacity(0.00)
                ],
                center: .center,
                startRadius: 0,
                endRadius: 180
            )
            .blendMode(.screen)
            .scaleEffect(1 + (maxScale - 1) * t)
            .opacity(1 - t)
        }
        .allowsHitTesting(false)
        .onAppear {
            for i in 0..<repeatWaves {
                let delay = Double(i) * (duration * 0.35)
//                let start = Double(i) * (duration * 0.35)
                withAnimation(.easeOut(duration: duration).delay(delay)) {
                    t = 1
                }
            }
        }
    }
}
