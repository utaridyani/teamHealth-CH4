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
    @State private var showMainMenu = false
    
    // Burst animation state
    @State private var burstBubbles: [BurstBubble] = []
    @State private var childBubbles: [ChildBubble] = []
    @State private var showBurst = false
    
    // Star animation - now shared with app
    @Binding var stars: [Star]
    @Binding var selectedSphereType: SphereType
    private let starCount = 80
    
    // Background transition
    @State private var backgroundTransition: Double = 0.0
    @State private var currentSphereType: SphereType = .dawn
    
    // Timer for animations
    private let animationTimer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()
    
    var onComplete: () -> Void
    
    var body: some View {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        GeometryReader { geo in
            ZStack {
                // Background gradient with smooth transition
                Group {
                    // Onboarding background
                    LinearGradient(
                        stops: [
                            Gradient.Stop(color: Color(red: 0.05, green: 0.05, blue: 0.05), location: 0.00),
                            Gradient.Stop(color: Color(red: 0.1, green: 0.1, blue: 0.15), location: 1.00),
                        ],
                        startPoint: UnitPoint(x: 0.1, y: -0.02),
                        endPoint: UnitPoint(x: 1.18, y: 2.00)
                    )
                    .opacity(1.0 - backgroundTransition)
                    
                    // Main menu background
                    currentSphereType.backgroundGradient
                        .opacity(backgroundTransition)
                }
                .ignoresSafeArea()
                
                // Animated stars
                ForEach(stars) { star in
                    let starPosition = star.position(centerX: screenWidth/2, centerY: screenHeight/2)
                    
                    Circle()
                        .fill(Color.white.opacity(star.currentOpacity * 0.6))
                        .frame(width: star.currentSize, height: star.currentSize)
                        .position(starPosition)
                        .blur(radius: star.distance < 50 ? 0.5 : 0)
                }
                
                // Onboarding content that fades out
                if !showMainMenu {
                    if currentPage == 0 {
                        // First page - "Express without word"
                        VStack(spacing: 60) {
                            VStack(spacing: 20) {
                                Text("Express without word")
                                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 100)
                            
                            Spacer()
                            
                            // White Glowing Sphere (smaller)
                            WhiteGlowingSphereView(
                                isActive: true,
                                scale: $sphereScale,
                                glowIntensity: $sphereGlowIntensity,
                                size: 160,
                                enableBounce: true
                            )
                            .opacity(showBurst ? 0 : 1)
                            .scaleEffect(showBurst ? 0.1 : 1)
                            .animation(.easeIn(duration: 0.3), value: showBurst)
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
                        .opacity(1.0 - backgroundTransition)
                        .transition(.opacity)
                        
                    } else {
                        // Second page - "Tap to feel the vibration"
                        VStack(spacing: 60) {
                            Spacer()
                            
                            // Larger White Glowing Sphere
                            WhiteGlowingSphereView(
                                isActive: true,
                                scale: $sphereScale,
                                glowIntensity: $sphereGlowIntensity,
                                size: 200,
                                enableBounce: true
                            )
                            .opacity(showBurst ? 0 : 1)
                            .scaleEffect(showBurst ? 0.1 : 1)
                            .animation(.easeIn(duration: 0.3), value: showBurst)
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
                        .opacity(1.0 - backgroundTransition)
                        .transition(.opacity)
                    }
                }
                
                // Main Menu that fades in
                if showMainMenu {
                    MainMenuContentView(
                        stars: $stars,
                        currentSphereType: $currentSphereType
                    )
                    .opacity(backgroundTransition)
                    .transition(.opacity)
                }
                
                // Enhanced burst bubbles with child bubbles
                if showBurst {
                    ZStack {
                        // Main burst bubbles
                        ForEach(burstBubbles) { bubble in
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            Color.white.opacity(bubble.opacity),
                                            Color.white.opacity(bubble.opacity * 0.7),
                                            Color.white.opacity(bubble.opacity * 0.3)
                                        ],
                                        center: .center,
                                        startRadius: 2,
                                        endRadius: bubble.radius
                                    )
                                )
                                .frame(width: bubble.currentSize, height: bubble.currentSize)
                                .position(bubble.position)
                                .blur(radius: 2)
                                .shadow(color: Color.white.opacity(0.4), radius: 5)
                        }
                        
                        // Child bubbles
                        ForEach(childBubbles) { childBubble in
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            Color.white.opacity(childBubble.opacity),
                                            Color.white.opacity(childBubble.opacity * 0.6),
                                            Color.clear
                                        ],
                                        center: .center,
                                        startRadius: 1,
                                        endRadius: childBubble.radius
                                    )
                                )
                                .frame(width: childBubble.currentSize, height: childBubble.currentSize)
                                .position(childBubble.position)
                                .blur(radius: 1)
                                .shadow(color: Color.white.opacity(0.3), radius: 3)
                        }
                    }
                    .allowsHitTesting(false)
                }
                
                // Navigation dots
                if !isTransitioning && !showMainMenu {
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
                }
            }
            .onAppear {
                initializeStars()
            }
            .onReceive(animationTimer) { _ in
                updateStars()
                updateBurstBubbles()
                updateChildBubbles()
            }
            .gesture(
                DragGesture()
                    .onEnded { value in
                        if !isTransitioning && !showBurst {
                            if value.translation.width < -50 && currentPage == 0 {
                                // Swipe left to next page
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    currentPage = 1
                                }
                            } else if value.translation.width > 50 && currentPage == 1 {
                                // Swipe right to previous page
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
                    HapticManager.playAHAP(named: "bubble")
                    
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0)) {
                        sphereScale = 0.85
                        sphereGlowIntensity = 1.3
                    }
                    
                    // Hold to complete onboarding
                    let work = DispatchWorkItem {
                        if !self.isTransitioning {
                            self.triggerBurst()
                        }
                    }
                    holdWork = work
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: work)
                    
                } else if isPressing {
                    // Continuous haptic while holding
                    let now = Date()
                    if now.timeIntervalSince(lastHapticTime) > 0.2 {
                        lastHapticTime = now
                        HapticManager.playAHAP(named: "bubble")
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
    
    // MARK: - Burst Animation
    private func triggerBurst() {
        isTransitioning = true
        
        // Success haptic
        HapticManager.notification(.success)
        
        // Create burst bubbles - more intense burst
        let centerX = UIScreen.main.bounds.width / 2
        let centerY = UIScreen.main.bounds.height / 2
        
        // Main burst bubbles (larger, faster)
        burstBubbles = (0..<35).map { _ in
            let angle = Double.random(in: 0..<2 * .pi)
            let speed = CGFloat.random(in: 150...300)
            let initialVelocity = CGVector(
                dx: cos(angle) * speed,
                dy: sin(angle) * speed
            )
            
            return BurstBubble(
                position: CGPoint(x: centerX, y: centerY),
                velocity: initialVelocity,
                baseSize: CGFloat.random(in: 25...60),
                opacity: Double.random(in: 0.7...1.0)
            )
        }
        
        // Child bubbles (smaller, more numerous)
        childBubbles = (0..<50).map { _ in
            let angle = Double.random(in: 0..<2 * .pi)
            let speed = CGFloat.random(in: 80...180)
            let initialVelocity = CGVector(
                dx: cos(angle) * speed,
                dy: sin(angle) * speed
            )
            
            return ChildBubble(
                position: CGPoint(x: centerX, y: centerY),
                velocity: initialVelocity,
                baseSize: CGFloat.random(in: 8...25),
                opacity: Double.random(in: 0.5...0.8),
                lifespan: Double.random(in: 2.0...4.0)
            )
        }
        
        // Start burst animation
        withAnimation(.easeIn(duration: 0.3)) {
            showBurst = true
        }
        
        // Longer transition timing for extended burst
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            // Start smooth transition
            withAnimation(.easeInOut(duration: 2.0)) {
                self.showMainMenu = true
                self.backgroundTransition = 1.0
                self.selectedSphereType = self.currentSphereType
            }
            
            // Complete transition
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.onComplete()
            }
        }
    }
    
    // MARK: - Burst Bubble Updates
    private func updateBurstBubbles() {
        guard showBurst else { return }
        
        for i in burstBubbles.indices {
            var bubble = burstBubbles[i]
            
            // Update position (no gravity, just spread outward)
            bubble.position.x += bubble.velocity.dx * 0.016
            bubble.position.y += bubble.velocity.dy * 0.016
            
            // Fade out
            bubble.opacity *= 0.985
            
            // Slow down
            bubble.velocity.dx *= 0.992
            bubble.velocity.dy *= 0.992
            
            burstBubbles[i] = bubble
        }
        
        // Remove faded bubbles
        burstBubbles.removeAll { $0.opacity < 0.05 }
    }
    
    // MARK: - Child Bubble Updates
    private func updateChildBubbles() {
        guard showBurst else { return }
        
        for i in childBubbles.indices {
            var bubble = childBubbles[i]
            
            // Update position (no gravity, just spread outward)
            bubble.position.x += bubble.velocity.dx * 0.016
            bubble.position.y += bubble.velocity.dy * 0.016
            
            // Air resistance only
            bubble.velocity.dx *= 0.995
            bubble.velocity.dy *= 0.995
            
            // Fade out over time
            bubble.age += 0.016
            let ageRatio = bubble.age / bubble.lifespan
            bubble.opacity = max(0, bubble.baseOpacity * (1.0 - ageRatio))
            
            childBubbles[i] = bubble
        }
        
        // Remove dead bubbles
        childBubbles.removeAll { $0.opacity <= 0.05 }
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
            stars[i].distance += stars[i].speed / 300.0
            
            if stars[i].distance > maxDistance {
                stars[i] = Star()
            }
        }
    }
}

// MARK: - Main Menu Content View
struct MainMenuContentView: View {
    @Binding var stars: [Star]
    @Binding var currentSphereType: SphereType
    @State private var selection = 0
    @State private var sphereScale: CGFloat = 1.0
    @State private var sphereGlowIntensity: Double = AnimationConstants.sphereGlowIntensity
    
    var body: some View {
        VStack {
            Spacer()
            
            TabView(selection: $selection) {
                ForEach(SphereType.allCases, id: \.rawValue) { sphereType in
                    VStack(spacing: 40) {
                        GlowingSphereView(
                            sphereType: sphereType,
                            isActive: currentSphereType == sphereType,
                            scale: $sphereScale,
                            glowIntensity: $sphereGlowIntensity
                        )
                        
                        SphereLabelView(
                            sphereType: sphereType,
                            isExpanded: false
                        )
                    }
                    .tag(sphereType.rawValue)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: UIScreen.main.bounds.height * 0.6)
            
            Spacer()
        }
        .onAppear {
            currentSphereType = SphereType(rawValue: selection) ?? .dawn
        }
        .onChange(of: selection) { newValue in
            withAnimation(.easeInOut(duration: 0.3)) {
                currentSphereType = SphereType(rawValue: newValue) ?? .dawn
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

// MARK: - Child Bubble Model
struct ChildBubble: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGVector
    var baseSize: CGFloat
    var opacity: Double
    let baseOpacity: Double
    var age: Double = 0
    let lifespan: Double
    
    init(position: CGPoint, velocity: CGVector, baseSize: CGFloat, opacity: Double, lifespan: Double) {
        self.position = position
        self.velocity = velocity
        self.baseSize = baseSize
        self.opacity = opacity
        self.baseOpacity = opacity
        self.lifespan = lifespan
    }
    
    var currentSize: CGFloat {
        return baseSize * CGFloat(opacity / baseOpacity)
    }
    
    var radius: CGFloat { currentSize / 2 }
}

// MARK: - Burst Bubble Model
struct BurstBubble: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGVector
    var baseSize: CGFloat
    var opacity: Double
    
    var currentSize: CGFloat {
        return baseSize * CGFloat(opacity)
    }
    
    var radius: CGFloat { currentSize / 2 }
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
