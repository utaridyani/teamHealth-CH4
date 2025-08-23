//
//  UnifiedMainView.swift
//  teamHealth
//
//  Created by Zap on 23/08/25.
//

import SwiftUI

struct UnifiedMainView: View {
    @EnvironmentObject var selectedHaptic: SelectedHaptic
    @StateObject private var bubbleManager = BubblePhysicsManager()
    @StateObject private var bigBangEffect = BigBangEffectManager()
    @StateObject private var enhancedBurst = EnhancedBurstManager()
    @StateObject private var soundManager = SoundManager.shared
    
    // View State Management
    enum ViewPhase {
        case onboardingPage1
        case onboardingPage2
        case bigBangTransition
        case sphereSelection
        case expandedBubbles
    }
    
    @State private var currentPhase: ViewPhase = .onboardingPage1
    @State private var isTransitioning = false
    
    // Shared Star Animation
    @State private var stars: [Star] = []
    private let starCount = 100
    
    // Sphere States
    @State private var currentSphereType: SphereType = .dawn
    @State private var selection = 0
    @State private var currentIndex = 0
    @State private var dragOffset: CGFloat = 0
    
    // Onboarding Sphere States
    @State private var onboardingSphereScale: CGFloat = 1.0
    @State private var onboardingSphereGlowIntensity: Double = AnimationConstants.sphereGlowIntensity
    @State private var onboardingSphereOpacity: Double = 1
    @State private var isPressing = false
    @State private var holdWork: DispatchWorkItem?
    @State private var lastHapticTime: Date = .distantPast
    
    // Menu Sphere States
    @State private var menuSphereScale: CGFloat = 1.0
    @State private var menuSphereGlowIntensity: Double = AnimationConstants.sphereGlowIntensity
    @State private var sphereBreathingPhase: CGFloat = 0
    @State private var quickTapBreathing = false
    
    // Background Transitions
    @State private var blackBackgroundOpacity: Double = 1
    @State private var backgroundStarOpacity: Double = 0
    @State private var sphereSelectionOpacity: Double = 0
    
    // Selection Burst Effect
    @State private var selectionBurstBubbles: [SelectionBurst] = []
    @State private var showSelectionBurst = false
    
    // Touch Tracking for Bubbles
    @State private var touches: [Int: CGPoint] = [:]
    @State private var lastTimes: [Int: Date] = [:]
    @State private var idleTouchPositions: [Int: CGPoint] = [:]
    @State private var idleTimers: [Int: Timer] = [:]
    @State private var lastIdleHapticTime: Date = .distantPast
    private let idleThreshold: CGFloat = 5.0
    private let idleHapticInterval: TimeInterval = 0.3
    
    // Three Finger Gesture
    @State private var threeIDs: Set<Int> = []
    @State private var threeStartPositions: [Int:CGPoint] = [:]
    @State private var threeHoldWork: DispatchWorkItem?
    @State private var threeFingersHold = false
    let threeMoveTolerance: CGFloat = 30
    
    // Timers
    private let animationTimer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        GeometryReader { geo in
            ZStack {
                // Layer 1: Background Management
                backgroundLayer
                
                // Layer 2: Sound Toggle (Always Visible)
                VStack {
                    HStack {
                        SoundToggleButton(color: currentPhase == .onboardingPage1 || currentPhase == .onboardingPage2 ? .white : currentSphereType.baseColor)
                            .padding(.leading, 20)
                            .padding(.top, 50)
                            .animation(.easeInOut(duration: 0.3), value: currentPhase)
                        Spacer()
                    }
                    Spacer()
                }
                .zIndex(100)
                
                // Layer 3: Animated Stars (Continuous)
                ForEach(stars) { star in
                    let starPosition = star.position(centerX: screenWidth/2, centerY: screenHeight/2)
                    
                    Circle()
                        .fill(Color.white.opacity(star.currentOpacity * (0.3 + backgroundStarOpacity * 0.5)))
                        .frame(width: star.currentSize, height: star.currentSize)
                        .position(starPosition)
                        .blur(radius: star.distance < 50 ? 0.5 : 0)
                }
                
                // Layer 4: Content Based on Phase
                contentLayer(geo: geo)
                
                // Layer 5: Effects Overlay
                effectsOverlay(screenWidth: screenWidth, screenHeight: screenHeight)
                
                // Layer 6: Navigation Dots for Onboarding
                if currentPhase == .onboardingPage1 || currentPhase == .onboardingPage2 {
                    navigationDots
                }
            }
            .onAppear {
                initializeStars()
                soundManager.playTrack("Onboarding")
            }
            .onReceive(animationTimer) { _ in
                updateAnimations()
            }
            .onChange(of: currentSphereType) { newType in
                soundManager.playTrack(soundManager.trackName(for: newType))
            }
            .gesture(createSwipeGesture())
        }
        .navigationBarBackButtonHidden()
    }
    
    // MARK: - Background Layer
    private var backgroundLayer: some View {
        ZStack {
            // Black background for onboarding
            Color.black
                .opacity(blackBackgroundOpacity)
                .ignoresSafeArea()
            
            // Gradient background for main menu
            currentSphereType.backgroundGradient
                .opacity(1.0 - blackBackgroundOpacity)
                .ignoresSafeArea()
        }
    }
    
    // MARK: - Content Layer
    @ViewBuilder
    private func contentLayer(geo: GeometryProxy) -> some View {
        switch currentPhase {
        case .onboardingPage1:
            onboardingPage1Content
                .opacity(onboardingSphereOpacity)
                .transition(.opacity)
            
        case .onboardingPage2:
            onboardingPage2Content
                .opacity(onboardingSphereOpacity)
                .transition(.opacity)
            
        case .bigBangTransition:
            EmptyView()
            
        case .sphereSelection:
            sphereSelectionContent(geo: geo)
                .opacity(sphereSelectionOpacity)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.1).combined(with: .opacity),
                    removal: .scale(scale: 1.5).combined(with: .opacity)
                ))
            
        case .expandedBubbles:
            expandedBubblesContent
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.1).combined(with: .opacity),
                    removal: .scale(scale: 1.5).combined(with: .opacity)
                ))
        }
    }
    
    // MARK: - Onboarding Page 1
    private var onboardingPage1Content: some View {
        VStack(spacing: 60) {
            VStack(spacing: 20) {
                Text("Express without word")
                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 100)
            
            Spacer()
            
            WhiteGlowingSphereView(
                isActive: true,
                scale: $onboardingSphereScale,
                glowIntensity: $onboardingSphereGlowIntensity,
                size: 160,
                enableBounce: true
            )
            .scaleEffect(bigBangEffect.isExploding ? 0.01 : 1)
            .gesture(createOnboardingSphereGesture())
            
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
    }
    
    // MARK: - Onboarding Page 2
    private var onboardingPage2Content: some View {
        VStack(spacing: 60) {
            Spacer()
            
            WhiteGlowingSphereView(
                isActive: true,
                scale: $onboardingSphereScale,
                glowIntensity: $onboardingSphereGlowIntensity,
                size: 200,
                enableBounce: true
            )
            .scaleEffect(bigBangEffect.isExploding ? 0.01 : 1)
            .gesture(createOnboardingSphereGesture())
            
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
    
    // MARK: - Navigation Dots
    private var navigationDots: some View {
        VStack {
            Spacer()
            HStack(spacing: 12) {
                ForEach(0..<2, id: \.self) { index in
                    Circle()
                        .fill(Color.white.opacity(dotOpacity(for: index)))
                        .frame(width: 8, height: 8)
                        .scaleEffect(dotScale(for: index))
                        .animation(.easeInOut(duration: 0.3), value: currentPhase)
                }
            }
            .padding(.bottom, 40)
        }
        .opacity(onboardingSphereOpacity)
    }
    
    private func dotOpacity(for index: Int) -> Double {
        switch currentPhase {
        case .onboardingPage1: return index == 0 ? 0.8 : 0.3
        case .onboardingPage2: return index == 1 ? 0.8 : 0.3
        default: return 0.3
        }
    }
    
    private func dotScale(for index: Int) -> CGFloat {
        switch currentPhase {
        case .onboardingPage1: return index == 0 ? 1.2 : 1.0
        case .onboardingPage2: return index == 1 ? 1.2 : 1.0
        default: return 1.0
        }
    }
    
    // MARK: - Sphere Selection Content
    @ViewBuilder
    private func sphereSelectionContent(geo: GeometryProxy) -> some View {
        VStack {
            Spacer()
            
            SphereCarouselView(
                currentIndex: $currentIndex,
                dragOffset: $dragOffset,
                currentSphereType: $currentSphereType,
                selection: $selection,
                sphereScale: $menuSphereScale,
                sphereGlowIntensity: $menuSphereGlowIntensity,
                sphereBreathingPhase: sphereBreathingPhase,
                quickTapBreathing: quickTapBreathing,
                isExpanded: false,
                createSphereGesture: createMenuSphereGesture
            )
            .frame(height: geo.size.height * 0.6)
            
            if showSelectionBurst {
                ForEach(selectionBurstBubbles) { burst in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.white.opacity(burst.opacity),
                                    burst.color.opacity(burst.opacity * 0.8),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 2,
                                endRadius: burst.radius
                            )
                        )
                        .frame(width: burst.currentSize, height: burst.currentSize)
                        .position(burst.position)
                        .blur(radius: 1)
                }
            }
            
            Spacer()
        }
        .onChange(of: selection) { newValue in
            withAnimation(.easeInOut(duration: 0.3)) {
                currentSphereType = SphereType(rawValue: newValue) ?? .dawn
                currentIndex = newValue
            }
        }
        .onChange(of: currentIndex) { newValue in
            withAnimation(.easeInOut(duration: 0.3)) {
                currentSphereType = SphereType.allCases[newValue]
                selection = newValue
            }
        }
    }
    
    // MARK: - Expanded Bubbles Content
    private var expandedBubblesContent: some View {
        ZStack {
            MultiTouchView(
                onChange: { newTouches in
                    handleTouchChange(newTouches)
                },
                isArmed: { threeFingersHold },
                onRight: {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        currentPhase = .sphereSelection
                        bubbleManager.clearAll()
                        touches.removeAll()
                        threeFingersHold = false
                        menuSphereScale = 1.0
                        menuSphereGlowIntensity = AnimationConstants.sphereGlowIntensity
                        cleanupIdleDetection()
                    }
                    HapticManager.selection()
                }
            )
            .ignoresSafeArea()
            
            ForEach(bubbleManager.touchBubbles) { bubble in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                bubble.color.opacity(bubble.opacity * 1.2),
                                bubble.color.opacity(bubble.opacity * 0.8),
                                bubble.color.opacity(bubble.opacity * 0.4)
                            ],
                            center: .center,
                            startRadius: 5,
                            endRadius: bubble.radius
                        )
                    )
                    .frame(width: bubble.currentSize, height: bubble.currentSize)
                    .position(bubble.position)
                    .blur(radius: 3)
                    .shadow(color: bubble.color.opacity(0.6), radius: 8)
                    .allowsHitTesting(false)
                    .animation(.easeOut(duration: 0.1), value: bubble.position)
            }
            
            if threeFingersHold {
                VStack {
                    Text("Swipe right to go back")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(Color.black.opacity(0.7))
                                .blur(radius: 1)
                        )
                    Spacer()
                }
                .padding(.top, 50)
                .transition(.opacity)
            }
        }
    }
    
    // MARK: - Effects Overlay
    @ViewBuilder
    private func effectsOverlay(screenWidth: CGFloat, screenHeight: CGFloat) -> some View {
        BigBangVisualEffect(
            effectManager: bigBangEffect,
            centerX: screenWidth / 2,
            centerY: screenHeight / 2
        )
        
        ForEach(enhancedBurst.particles) { particle in
            Circle()
                .fill(particle.color.opacity(particle.opacity))
                .frame(width: particle.size, height: particle.size)
                .position(particle.position)
                .rotationEffect(.radians(particle.rotation))
                .blur(radius: particle.opacity < 0.5 ? 2 : 0)
                .allowsHitTesting(false)
        }
    }
    
    // MARK: - Gesture Handlers
    private func createSwipeGesture() -> some Gesture {
        DragGesture()
            .onEnded { value in
                guard !isTransitioning && !bigBangEffect.isExploding else { return }
                
                switch currentPhase {
                case .onboardingPage1:
                    if value.translation.width < -50 {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            currentPhase = .onboardingPage2
                        }
                    }
                case .onboardingPage2:
                    if value.translation.width > 50 {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            currentPhase = .onboardingPage1
                        }
                    }
                default:
                    break
                }
            }
    }
    
    private func createOnboardingSphereGesture() -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                if !isPressing && !isTransitioning {
                    isPressing = true
                    
                    HapticManager.playAHAP(named: "drum")
                    
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0)) {
                        onboardingSphereScale = 0.85
                        onboardingSphereGlowIntensity = 1.3
                    }
                    
                    let work = DispatchWorkItem {
                        if !self.isTransitioning {
                            self.triggerBigBang()
                        }
                    }
                    holdWork = work
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: work)
                    
                } else if isPressing {
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
                        onboardingSphereScale = 1.0
                        onboardingSphereGlowIntensity = AnimationConstants.sphereGlowIntensity
                    }
                }
            }
    }
    
    private func createMenuSphereGesture(for sphereType: SphereType) -> AnyGesture<DragGesture.Value> {
        return AnyGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressing {
                        isPressing = true
                        
                        triggerHaptic(for: sphereType.hapticID)
                        
                        quickTapBreathing = true
                        sphereBreathingPhase = 0
                        
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0)) {
                            menuSphereScale = 0.85
                            menuSphereGlowIntensity = 1.3
                        }
                        
                        withAnimation(.easeInOut(duration: 0.5)) {
                            menuSphereScale = 0.9
                        }
                        
                        let work = DispatchWorkItem {
                            print("Expanding sphere \(sphereType.name)")
                            
                            selectedHaptic.selectedCircle = sphereType.hapticID
                            selectedHaptic.selectedColor = sphereType.baseColor
                            
                            HapticManager.notification(.success)
                            
                            self.createSelectionStarBurst(for: sphereType)
                            
                            withAnimation(.easeIn(duration: 0.3)) {
                                menuSphereScale = 0.1
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                    self.currentPhase = .expandedBubbles
                                    self.menuSphereScale = 1.0
                                    self.quickTapBreathing = false
                                }
                            }
                        }
                        holdWork = work
                        DispatchQueue.main.asyncAfter(deadline: .now() + AnimationConstants.sphereHoldDuration, execute: work)
                        
                    } else {
                        let now = Date()
                        if now.timeIntervalSince(lastHapticTime) > AnimationConstants.hapticInterval {
                            lastHapticTime = now
                            triggerHaptic(for: sphereType.hapticID)
                        }
                    }
                }
                .onEnded { _ in
                    isPressing = false
                    holdWork?.cancel()
                    holdWork = nil
                    
                    if currentPhase == .sphereSelection && !quickTapBreathing {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            menuSphereScale = 1.0
                            menuSphereGlowIntensity = AnimationConstants.sphereGlowIntensity
                        }
                    }
                }
        )
    }
    
    // MARK: - Big Bang Transition
    private func triggerBigBang() {
        isTransitioning = true
        currentPhase = .bigBangTransition
        
        let centerX = UIScreen.main.bounds.width / 2
        let centerY = UIScreen.main.bounds.height / 2
        enhancedBurst.createBigBangParticles(at: CGPoint(x: centerX, y: centerY), count: 150)
        
        bigBangEffect.triggerBigBang(stars: &stars)
        
        withAnimation(.easeOut(duration: 0.3)) {
            onboardingSphereOpacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 2.0)) {
                blackBackgroundOpacity = 0
                backgroundStarOpacity = 1.0
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            currentPhase = .sphereSelection
            
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7, blendDuration: 0)) {
                menuSphereScale = 1.0
                sphereSelectionOpacity = 1.0
            }
            
            soundManager.playTrack(soundManager.trackName(for: currentSphereType))
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            isTransitioning = false
        }
    }
    
    // MARK: - Animation Updates
    private func updateAnimations() {
        updateStars()
        bigBangEffect.updateExplosion()
        enhancedBurst.updateParticles()
        
        if currentPhase == .expandedBubbles {
            bubbleManager.updatePhysics()
            checkIdleBubbleCollisions()
        }
        
        updateSelectionBurst()
        
        if quickTapBreathing {
            sphereBreathingPhase += 0.15
            if sphereBreathingPhase > .pi * 2 {
                sphereBreathingPhase = 0
                quickTapBreathing = false
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    menuSphereScale = 1.0
                }
            }
        }
    }
    
    // MARK: - Star Management
    private func initializeStars() {
        if stars.isEmpty {
            stars = (0..<starCount).map { index in
                var star = Star()
                star.distance = CGFloat(index) * 5.0 + CGFloat.random(in: 1...20)
                return star
            }
        }
    }
    
    private func updateStars() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let maxDistance = sqrt(pow(screenWidth, 2) + pow(screenHeight, 2)) + 100
        
        for i in stars.indices {
            stars[i].distance += stars[i].speed / 200.0
            
            if stars[i].distance > maxDistance {
                stars[i] = Star()
                if bigBangEffect.isExploding {
                    stars[i].speed = CGFloat.random(in: 100...300)
                }
            }
        }
    }
    
    // MARK: - Star Burst Effect
    private func createSelectionStarBurst(for sphereType: SphereType) {
        let screenWidth = UIScreen.main.bounds.width
        let centerX = screenWidth / 2
        let centerY = UIScreen.main.bounds.height * 0.4
        
        selectionBurstBubbles = []
        
        let starPoints = 5
        
        for point in 0..<starPoints {
            let pointAngle = Double(point) * (2 * .pi / Double(starPoints))
            
            for ray in 0..<6 {
                let spreadAngle = pointAngle + Double.random(in: -0.1...0.1)
                let speed = CGFloat(200 + ray * 40)
                
                let initialVelocity = CGVector(
                    dx: cos(Double(spreadAngle)) * speed,
                    dy: sin(Double(spreadAngle)) * speed
                )
                
                let burst = SelectionBurst(
                    position: CGPoint(x: centerX, y: centerY),
                    velocity: initialVelocity,
                    baseSize: CGFloat.random(in: 20...40),
                    opacity: Double.random(in: 0.7...1.0),
                    color: sphereType.baseColor
                )
                selectionBurstBubbles.append(burst)
            }
        }
        
        for _ in 0..<15 {
            let angle = Double.random(in: 0..<2 * .pi)
            let speed = CGFloat.random(in: 100...250)
            
            let initialVelocity = CGVector(
                dx: cos(Double(angle)) * speed,
                dy: sin(Double(angle)) * speed
            )
            
            let burst = SelectionBurst(
                position: CGPoint(x: centerX, y: centerY),
                velocity: initialVelocity,
                baseSize: CGFloat.random(in: 15...30),
                opacity: Double.random(in: 0.5...0.8),
                color: sphereType.baseColor
            )
            selectionBurstBubbles.append(burst)
        }
        
        withAnimation(.easeOut(duration: 0.2)) {
            showSelectionBurst = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showSelectionBurst = false
            selectionBurstBubbles.removeAll()
        }
    }
    
    private func updateSelectionBurst() {
        guard showSelectionBurst else { return }
        
        for i in selectionBurstBubbles.indices {
            var burst = selectionBurstBubbles[i]
            
            burst.position.x += burst.velocity.dx * 0.016
            burst.position.y += burst.velocity.dy * 0.016
            burst.opacity *= 0.97
            burst.velocity.dx *= 0.99
            burst.velocity.dy *= 0.99
            
            selectionBurstBubbles[i] = burst
        }
        
        selectionBurstBubbles.removeAll { $0.opacity < 0.05 }
    }
    
    // MARK: - Touch Handling
    private func handleTouchChange(_ newTouches: [Int: CGPoint]) {
        let previousTouches = touches
        touches = newTouches
        bubbleManager.updateTouches(newTouches, sphereType: currentSphereType)
        
        let now = Date()
        let screenHeight = UIScreen.main.bounds.height
        
        for (id, point) in newTouches {
            if let previousPoint = previousTouches[id] {
                let dx = point.x - previousPoint.x
                let dy = point.y - previousPoint.y
                let movement = sqrt(dx*dx + dy*dy)
                
                if movement < idleThreshold {
                    if idleTouchPositions[id] == nil {
                        idleTouchPositions[id] = point
                        startIdleHapticTimer(for: id, at: point)
                    }
                } else {
                    stopIdleHapticTimer(for: id)
                    idleTouchPositions.removeValue(forKey: id)
                    
                    if now.timeIntervalSince(lastTimes[id] ?? .distantPast) > AnimationConstants.hapticInterval {
                        lastTimes[id] = now
                        
                        if let a = area(for: point.y, totalHeight: screenHeight) {
                            triggerHapticByCircle(for: currentSphereType.hapticID, area: a)
                        }
                    }
                }
            } else {
                idleTouchPositions[id] = point
                startIdleHapticTimer(for: id, at: point)
            }
        }
        
        let removedTouches = Set(previousTouches.keys).subtracting(Set(newTouches.keys))
        for id in removedTouches {
            stopIdleHapticTimer(for: id)
            idleTouchPositions.removeValue(forKey: id)
            lastTimes.removeValue(forKey: id)
        }
        
        let ids = Set(newTouches.keys)
        if ids.count == 3 {
            if ids != threeIDs {
                threeHoldWork?.cancel()
                threeIDs = ids
                threeStartPositions = newTouches
                
                let work = DispatchWorkItem { [ids] in
                    guard self.threeIDs == ids else { return }
                    let ok = ids.allSatisfy { id in
                        guard let start = self.threeStartPositions[id],
                              let cur = self.touches[id] else { return false }
                        let dx = start.x - cur.x, dy = start.y - cur.y
                        return sqrt(dx*dx + dy*dy) <= self.threeMoveTolerance
                    }
                    if ok {
                        withAnimation {
                            self.threeFingersHold = true
                        }
                        HapticManager.selection()
                        print("3 fingers hold armed")
                    }
                }
                threeHoldWork = work
                DispatchQueue.main.asyncAfter(deadline: .now() + AnimationConstants.threeFingerHoldDuration, execute: work)
            }
        } else {
            threeHoldWork?.cancel()
            threeHoldWork = nil
            threeIDs = []
            threeStartPositions = [:]
            if threeFingersHold {
                withAnimation {
                    threeFingersHold = false
                }
            }
        }
    }
    
    // MARK: - Idle Haptic Management
    private func startIdleHapticTimer(for touchID: Int, at point: CGPoint) {
        stopIdleHapticTimer(for: touchID)
        
        let timer = Timer.scheduledTimer(withTimeInterval: idleHapticInterval, repeats: true) { _ in
            self.playIdleHaptic(for: touchID, at: point)
        }
        idleTimers[touchID] = timer
        
        playIdleHaptic(for: touchID, at: point)
    }
    
    private func stopIdleHapticTimer(for touchID: Int) {
        idleTimers[touchID]?.invalidate()
        idleTimers.removeValue(forKey: touchID)
    }
    
    private func playIdleHaptic(for touchID: Int, at point: CGPoint) {
        for bubble in bubbleManager.touchBubbles {
            let dx = point.x - bubble.position.x
            let dy = point.y - bubble.position.y
            let distance = sqrt(dx*dx + dy*dy)
            
            if distance <= bubble.currentSize / 2 {
                let dir = direction(for: point, in: UIScreen.main.bounds)
                playDirectionalBubbleHaptic(dir)
                return
            }
        }
    }
    
    private func checkIdleBubbleCollisions() {
        for (touchID, point) in idleTouchPositions {
            var isOnBubble = false
            for bubble in bubbleManager.touchBubbles {
                let dx = point.x - bubble.position.x
                let dy = point.y - bubble.position.y
                let distance = sqrt(dx*dx + dy*dy)
                
                if distance <= bubble.currentSize / 2 {
                    isOnBubble = true
                    break
                }
            }
            
            if !isOnBubble && idleTimers[touchID] != nil {
                stopIdleHapticTimer(for: touchID)
                startIdleHapticTimer(for: touchID, at: point)
            }
        }
    }
    
    private func cleanupIdleDetection() {
        for (id, _) in idleTimers {
            stopIdleHapticTimer(for: id)
        }
        idleTouchPositions.removeAll()
    }
    
    // MARK: - Helper Functions
    private func direction(for point: CGPoint, in bounds: CGRect) -> String {
        let third = bounds.width / 3
        switch point.x {
        case 0..<third:
            return "left"
        case third..<third*2:
            return "center"
        default:
            return "right"
        }
    }
    
    func area(for y: CGFloat, totalHeight: CGFloat) -> Int? {
        guard totalHeight > 0 else { return nil }
        let h = totalHeight / 3
        switch y {
        case 0..<h: return 0
        case h..<(2*h): return 1
        case (2*h)...: return 2
        default: return nil
        }
    }
    
    func playDirectionalBubbleHaptic(_ dir: String) {
        switch dir {
        case "left":
            HapticManager.playAHAP(named: "bubble_pop_left")
        case "center":
            HapticManager.playAHAP(named: "bubble_pop")
        case "right":
            HapticManager.playAHAP(named: "bubble_pop_right")
        default:
            break
        }
    }
    
    func triggerHaptic(for circle: String) {
        switch circle {
        case "circle0":
            HapticManager.playAHAP(named: "dawn")
        case "circle1":
            HapticManager.playAHAP(named: "twilight")
        case "circle2":
            HapticManager.playAHAP(named: "reverie")
        default:
            break
        }
    }
    
    func triggerHapticByCircle(for circle: String, area: Int) {
        switch circle {
        case "circle0":
            HapticManager.playAHAP(named: "dawn")
        case "circle1":
            HapticManager.playAHAP(named: "twilight")
        case "circle2":
            HapticManager.playAHAP(named: "reverie")
        default:
            break
        }
    }
}

// MARK: - Selection Burst Model
struct SelectionBurst: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGVector
    var baseSize: CGFloat
    var opacity: Double
    var color: Color
    
    var currentSize: CGFloat {
        return baseSize * CGFloat(opacity)
    }
    
    var radius: CGFloat { currentSize / 2 }
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

// MARK: - Sphere Carousel View
struct SphereCarouselView: View {
    @Binding var currentIndex: Int
    @Binding var dragOffset: CGFloat
    @Binding var currentSphereType: SphereType
    @Binding var selection: Int
    @Binding var sphereScale: CGFloat
    @Binding var sphereGlowIntensity: Double
    let sphereBreathingPhase: CGFloat
    let quickTapBreathing: Bool
    let isExpanded: Bool
    let createSphereGesture: (SphereType) -> AnyGesture<DragGesture.Value>
    
    var body: some View {
        GeometryReader { carouselGeo in
            let carouselWidth = carouselGeo.size.width
            let sphereSpacing: CGFloat = carouselWidth * 0.7
            
            ZStack {
                // Create enough instances for smooth infinite scrolling
                ForEach(-2...4, id: \.self) { index in
                    SphereCarouselItem(
                        index: index,
                        currentIndex: currentIndex,
                        dragOffset: dragOffset,
                        sphereSpacing: sphereSpacing,
                        sphereScale: $sphereScale,
                        sphereGlowIntensity: $sphereGlowIntensity,
                        sphereBreathingPhase: sphereBreathingPhase,
                        quickTapBreathing: quickTapBreathing,
                        isExpanded: isExpanded,
                        createSphereGesture: createSphereGesture
                    )
                }
            }
            .frame(width: carouselWidth, height: carouselGeo.size.height)
            .clipped()
            .gesture(createCarouselDragGesture())
        }
    }
    
    private func createCarouselDragGesture() -> some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation.width
            }
            .onEnded { value in
                let dragThreshold: CGFloat = 50
                let velocityThreshold: CGFloat = 300
                
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    if value.translation.width > dragThreshold || value.velocity.width > velocityThreshold {
                        // Swipe right - go to previous
                        currentIndex = (currentIndex - 1 + SphereType.allCases.count) % SphereType.allCases.count
                    } else if value.translation.width < -dragThreshold || value.velocity.width < -velocityThreshold {
                        // Swipe left - go to next
                        currentIndex = (currentIndex + 1) % SphereType.allCases.count
                    }
                    dragOffset = 0
                    
                    // Update current sphere type
                    currentSphereType = SphereType.allCases[currentIndex]
                    selection = currentIndex
                }
            }
    }
}

// MARK: - Sphere Carousel Item
struct SphereCarouselItem: View {
    let index: Int
    let currentIndex: Int
    let dragOffset: CGFloat
    let sphereSpacing: CGFloat
    @Binding var sphereScale: CGFloat
    @Binding var sphereGlowIntensity: Double
    let sphereBreathingPhase: CGFloat
    let quickTapBreathing: Bool
    let isExpanded: Bool
    let createSphereGesture: (SphereType) -> AnyGesture<DragGesture.Value>
    
    private var sphereIndex: Int {
        // Proper modulo for infinite scrolling
        var actualIndex = index
        while actualIndex < 0 {
            actualIndex += SphereType.allCases.count
        }
        return actualIndex % SphereType.allCases.count
    }
    
    private var sphereType: SphereType {
        SphereType.allCases[sphereIndex]
    }
    
    private var isCurrentSphere: Bool {
        sphereIndex == currentIndex
    }
    
    private var relativePosition: Int {
        // Calculate relative position for infinite scroll
        var diff = index - currentIndex
        
        // Wrap around logic
        if diff > SphereType.allCases.count / 2 {
            diff -= SphereType.allCases.count
        } else if diff < -SphereType.allCases.count / 2 {
            diff += SphereType.allCases.count
        }
        
        return diff
    }
    
    private var totalOffset: CGFloat {
        CGFloat(relativePosition) * sphereSpacing + dragOffset
    }
    
    private var finalScale: CGFloat {
        if isCurrentSphere { return 1.0 }
        
        let distance = abs(relativePosition)
        if distance == 1 {
            // Adjacent spheres - make them smaller but visible
            return 0.7
        }
        return 0.5
    }
    
    private var finalOpacity: Double {
        if isCurrentSphere { return 1.0 }
        
        let distance = abs(relativePosition)
        if distance == 1 {
            // Adjacent spheres - partially visible
            return 0.4
        } else if distance == 2 {
            return 0.1
        }
        return 0
    }
    
    var body: some View {
        VStack(spacing: 40) {
            GlowingSphereView(
                sphereType: sphereType,
                isActive: isCurrentSphere,
                scale: $sphereScale,
                glowIntensity: $sphereGlowIntensity,
                breathingPhase: isCurrentSphere ? sphereBreathingPhase : 0,
                useCustomBreathing: isCurrentSphere && quickTapBreathing
            )
            .scaleEffect(finalScale)
            .opacity(finalOpacity)
            .gesture(createSphereGesture(sphereType))
            
            if isCurrentSphere {
                SphereLabelView(
                    sphereType: sphereType,
                    isExpanded: isExpanded
                )
                .opacity(finalOpacity)
            }
        }
        .offset(x: totalOffset)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: totalOffset)
    }
}

#Preview {
    UnifiedMainView()
        .environmentObject(SelectedHaptic())
        .environmentObject(HapticData())
}
