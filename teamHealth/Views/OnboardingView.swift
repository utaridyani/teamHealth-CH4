//
//  OnboardingView.swift
//  teamHealth
//
//  Created by Zap on 21/08/25.
//

import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var sphereScale: CGFloat = 1.0
    @State private var sphereGlowIntensity: Double = AnimationConstants.sphereGlowIntensity
    @State private var isPressing = false
    @State private var holdWork: DispatchWorkItem?
    @State private var lastHapticTime: Date = .distantPast
    @State private var isTransitioning = false
    
    // Big Bang Effect Manager
    @StateObject private var bigBangEffect = BigBangEffectManager()
    @StateObject private var enhancedBurst = EnhancedBurstManager()
    
    // Star animation - shared with app
    @Binding var stars: [Star]
    @Binding var selectedSphereType: SphereType
    private let starCount = 80
    
    // Transition states
    @State private var showSphereSelection = false
    @State private var sphereSelectionOpacity: Double = 0
    @State private var onboardingSphereOpacity: Double = 1
    @State private var backgroundStarOpacity: Double = 0
    @State private var blackBackgroundOpacity: Double = 1
    
    // Sphere selection states (for smooth transition)
    @State private var selection = 0
    @State private var menuSphereScale: CGFloat = 0.1
    @State private var menuSphereGlowIntensity: Double = AnimationConstants.sphereGlowIntensity
    
    // Timer for animations
    private let animationTimer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()
    
    var onComplete: () -> Void
    
    var body: some View {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        GeometryReader { geo in
            ZStack {
                // Layer 1: Black background for onboarding (fades out)
                Color.black
                    .opacity(blackBackgroundOpacity)
                    .ignoresSafeArea()
                
                // Layer 2: Main menu gradient background (fades in after explosion)
                selectedSphereType.backgroundGradient
                    .opacity(1.0 - blackBackgroundOpacity)
                    .ignoresSafeArea()
                
                // Layer 3: Animated stars (opacity changes during transition)
                ForEach(stars) { star in
                    let starPosition = star.position(centerX: screenWidth/2, centerY: screenHeight/2)
                    
                    Circle()
                        .fill(Color.white.opacity(star.currentOpacity * (0.3 + backgroundStarOpacity * 0.5)))
                        .frame(width: star.currentSize, height: star.currentSize)
                        .position(starPosition)
                        .blur(radius: star.distance < 50 ? 0.5 : 0)
                }
                
                // Layer 4: Onboarding content (fades out during transition)
                if !showSphereSelection {
                    Group {
                        if currentPage == 0 {
                            // First page
                            VStack(spacing: 60) {
                                VStack(spacing: 20) {
                                    Text("Express without word")
                                        .font(.system(size: 32, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(.top, 100)
                                
                                Spacer()
                                
                                // White Glowing Sphere
                                WhiteGlowingSphereView(
                                    isActive: true,
                                    scale: $sphereScale,
                                    glowIntensity: $sphereGlowIntensity,
                                    size: 160,
                                    enableBounce: true
                                )
                                .opacity(onboardingSphereOpacity)
                                .scaleEffect(bigBangEffect.isExploding ? 0.01 : 1)
                                .gesture(createSphereGesture())
                                
                                Spacer()
                                
                                VStack(spacing: 8) {
                                    Text("Say it with a living rhythm,")
                                        .font(.system(size: 18, weight: .medium, design: .rounded))
                                        .foregroundColor(.white.opacity(0.8))
                                    Text("when words won't land.")
                                        .font(.system(size: 18, weight: .medium, design: .rounded))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                .padding(.bottom, 80)
                            }
                            
                        } else {
                            // Second page
                            VStack(spacing: 60) {
                                Spacer()
                                
                                WhiteGlowingSphereView(
                                    isActive: true,
                                    scale: $sphereScale,
                                    glowIntensity: $sphereGlowIntensity,
                                    size: 200,
                                    enableBounce: true
                                )
                                .opacity(onboardingSphereOpacity)
                                .scaleEffect(bigBangEffect.isExploding ? 0.01 : 1)
                                .gesture(createSphereGesture())
                                
                                Spacer()
                                
                                VStack(spacing: 8) {
                                    Text("Tap to feel the vibration,")
                                        .font(.system(size: 18, weight: .medium, design: .rounded))
                                        .foregroundColor(.white.opacity(0.8))
                                    Text("hold to jump to the session.")
                                        .font(.system(size: 18, weight: .medium, design: .rounded))
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                .padding(.bottom, 80)
                            }
                        }
                    }
                    .opacity(onboardingSphereOpacity)
                    .transition(.opacity)
                }
                
                // Layer 5: Big Bang Visual Effect
                BigBangVisualEffect(
                    effectManager: bigBangEffect,
                    centerX: screenWidth / 2,
                    centerY: screenHeight / 2
                )
                
                // Enhanced particles from burst
                ForEach(enhancedBurst.particles) { particle in
                    Circle()
                        .fill(particle.color.opacity(particle.opacity))
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .rotationEffect(.radians(particle.rotation))
                        .blur(radius: particle.opacity < 0.5 ? 2 : 0)
                        .allowsHitTesting(false)
                }
                
                // Layer 6: Sphere Selection (emerges from explosion center)
                if showSphereSelection {
                    VStack {
                        Spacer()
                        
                        TabView(selection: $selection) {
                            ForEach(SphereType.allCases, id: \.rawValue) { sphereType in
                                VStack(spacing: 40) {
                                    GlowingSphereView(
                                        sphereType: sphereType,
                                        isActive: selectedSphereType == sphereType,
                                        scale: $menuSphereScale,
                                        glowIntensity: $menuSphereGlowIntensity
                                    )
                                    .scaleEffect(menuSphereScale)
                                    
                                    SphereLabelView(
                                        sphereType: sphereType,
                                        isExpanded: false
                                    )
                                    .opacity(sphereSelectionOpacity)
                                }
                                .tag(sphereType.rawValue)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .frame(height: UIScreen.main.bounds.height * 0.6)
                        .opacity(sphereSelectionOpacity)
                        
                        Spacer()
                    }
                }
                
                // Navigation dots for onboarding
                if !isTransitioning && !showSphereSelection {
                    VStack {
                        Spacer()
                        HStack(spacing: 12) {
                            ForEach(0..<2, id: \.self) { index in
                                Circle()
                                    .fill(Color.white.opacity(currentPage == index ? 0.8 : 0.3))
                                    .frame(width: 8, height: 8)
                                    .scaleEffect(currentPage == index ? 1.2 : 1.0)
                                    .animation(.easeInOut(duration: 0.3), value: currentPage)
                            }
                        }
                        .padding(.bottom, 40)
                    }
                    .opacity(onboardingSphereOpacity)
                }
            }
            .onAppear {
                initializeStars()
                selectedSphereType = .dawn
            }
            .onReceive(animationTimer) { _ in
                updateStars()
                bigBangEffect.updateExplosion()
                enhancedBurst.updateParticles()
            }
            .onChange(of: selection) { newValue in
                withAnimation(.easeInOut(duration: 0.3)) {
                    selectedSphereType = SphereType(rawValue: newValue) ?? .dawn
                }
            }
            .gesture(
                DragGesture()
                    .onEnded { value in
                        if !isTransitioning && !bigBangEffect.isExploding && !showSphereSelection {
                            if value.translation.width < -50 && currentPage == 0 {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    currentPage = 1
                                }
                            } else if value.translation.width > 50 && currentPage == 1 {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    currentPage = 0
                                }
                            }
                        }
                    }
            )
        }
        .navigationBarBackButtonHidden()
    }
    
    // MARK: - Sphere Gesture
    private func createSphereGesture() -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                if !isPressing && !isTransitioning {
                    isPressing = true
                    
                    // Initial haptic and animation
                    HapticManager.playAHAP(named: "drum")
                    
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0)) {
                        sphereScale = 0.85
                        sphereGlowIntensity = 1.3
                    }
                    
                    // Hold to complete onboarding with Big Bang
                    let work = DispatchWorkItem {
                        if !self.isTransitioning {
                            self.triggerBigBang()
                        }
                    }
                    holdWork = work
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: work)
                    
                } else if isPressing {
                    // Continuous haptic while holding
                    let now = Date()
                    if now.timeIntervalSince(lastHapticTime) > 0.2 {
                        lastHapticTime = now
                        HapticManager.playAHAP(named: "drum")
                    }
                }
            }
            .onEnded { _ in
                isPressing = false
                holdWork?.cancel()
                holdWork = nil
                
                if !isTransitioning {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0)) {
                        sphereScale = 1.0
                        sphereGlowIntensity = AnimationConstants.sphereGlowIntensity
                    }
                }
            }
    }
    
    // MARK: - Big Bang Trigger with Smooth Transition
    private func triggerBigBang() {
        isTransitioning = true
        
        // Create enhanced particles at center
        let centerX = UIScreen.main.bounds.width / 2
        let centerY = UIScreen.main.bounds.height / 2
        enhancedBurst.createBigBangParticles(at: CGPoint(x: centerX, y: centerY), count: 150)
        
        // Trigger the big bang effect with stars
        bigBangEffect.triggerBigBang(stars: &stars)
        
        // Start fading out onboarding sphere immediately
        withAnimation(.easeOut(duration: 0.3)) {
            onboardingSphereOpacity = 0
        }
        
        // Phase 1: During explosion (0-1.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Start showing sphere selection while explosion is happening
            showSphereSelection = true
            
            // Begin background transition
            withAnimation(.easeInOut(duration: 2.0)) {
                blackBackgroundOpacity = 0
                backgroundStarOpacity = 1.0
            }
        }
        
        // Phase 2: Spheres emerge from explosion center (1.5-3s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7, blendDuration: 0)) {
                menuSphereScale = 1.0
                sphereSelectionOpacity = 1.0
            }
        }
        
        // Phase 3: Complete transition (4s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.onComplete()
        }
    }
    
    // MARK: - Star Management
    private func initializeStars() {
        if stars.isEmpty {
            stars = (0..<starCount).map { index in
                var star = Star()
                star.distance = CGFloat(index) * 8.0 + CGFloat.random(in: 1...40)
                return star
            }
        }
    }
    
    private func updateStars() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let maxDistance = sqrt(pow(screenWidth, 2) + pow(screenHeight, 2)) + 100
        
        for i in stars.indices {
            // Normal movement
            stars[i].distance += stars[i].speed / 300.0
            
            // Reset stars that go too far
            if stars[i].distance > maxDistance {
                stars[i] = Star()
                // If we're exploding, give new stars some initial velocity
                if bigBangEffect.isExploding {
                    stars[i].speed = CGFloat.random(in: 100...300)
                }
            }
        }
    }
}

// MARK: - White Glowing Sphere View
struct WhiteGlowingSphereView: View {
    let isActive: Bool
    @Binding var scale: CGFloat
    @Binding var glowIntensity: Double
    let size: CGFloat
    let enableBounce: Bool
    
    @State private var pulseAnimation = false
    @State private var rotationAngle: Double = 0
    @State private var breathingPhase: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Outer glow rings
            if isActive {
                ForEach(0..<3, id: \.self) { ring in
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.6 - Double(ring) * 0.2),
                                    Color.white.opacity(0.4 - Double(ring) * 0.15),
                                    Color.white.opacity(0.3 - Double(ring) * 0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: size + 60 + CGFloat(ring * 30), height: size + 60 + CGFloat(ring * 30))
                        .opacity(pulseAnimation ? 0.8 - Double(ring) * 0.2 : 0.3 - Double(ring) * 0.1)
                        .scaleEffect(pulseAnimation ? 1.1 : 0.95)
                        .rotationEffect(.degrees(rotationAngle + Double(ring * 30)))
                }
            }
            
            // Main sphere with bouncy breathing
            ZStack {
                // Base sphere with white gradient
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white,
                                Color.white.opacity(0.95),
                                Color.white.opacity(0.85),
                                Color.white.opacity(0.7)
                            ],
                            center: UnitPoint(x: 0.35, y: 0.25),
                            startRadius: 20,
                            endRadius: size/2
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
                            endRadius: size/4
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
                            startRadius: size/5,
                            endRadius: size/2
                        )
                    )
            }
            .frame(width: size, height: size)
            .scaleEffect(scale * (enableBounce ? (1.0 + sin(breathingPhase) * 0.08) : 1.0))
            
            // Outer glow effect
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.6),
                            Color.white.opacity(0.3),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: size/3,
                        endRadius: size/2 + 20
                    )
                )
                .frame(width: size + 40, height: size + 40)
                .scaleEffect(scale * (enableBounce ? (1.0 + sin(breathingPhase) * 0.05) : 1.0))
                .opacity(glowIntensity)
                .blur(radius: 10)
        }
        .shadow(color: Color.white.opacity(0.5), radius: 30, x: 0, y: 0)
        .shadow(color: Color.white.opacity(0.3), radius: 15, x: 0, y: 0)
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
            if enableBounce {
                breathingPhase += 0.03
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

#Preview {
    @State var previewStars: [Star] = []
    @State var previewSphereType: SphereType = .dawn
    
    return OnboardingView(
        stars: $previewStars,
        selectedSphereType: $previewSphereType
    ) {
        print("Onboarding completed")
    }
}
