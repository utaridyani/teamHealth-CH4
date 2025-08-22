//  MainMenuView.swift
//  test_haptics
//
//  Created by Utari Dyani Laksmi on 14/08/25.
//

import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject var selectedHaptic: SelectedHaptic
    @StateObject private var bubbleManager = BubblePhysicsManager()
    
    // Sphere selection state
    @State private var selection = 0
    @State private var currentSphereType: SphereType
    @State private var isPressing = false
    @State private var holdWork: DispatchWorkItem? = nil
    @State private var lastHapticTime: Date = .distantPast
    
    // Sphere animation states
    @State private var sphereScale: CGFloat = 1.0
    @State private var sphereGlowIntensity: Double = AnimationConstants.sphereGlowIntensity
    @State private var sphereBreathingPhase: CGFloat = 0
    @State private var quickTapBreathing = false
    
    // Star burst effect for sphere selection
    @State private var selectionBurstBubbles: [SelectionBurst] = []
    @State private var showSelectionBurst = false
    
    // Expanded mode state
    @State private var isExpanded = false
    
    // Star animation - can inherit from onboarding
    @State private var stars: [Star]
    private let starCount = 100
    
    // Touch tracking
    @State private var touches: [Int: CGPoint] = [:]
    @State private var lastTimes: [Int: Date] = [:]
    
    // Idle detection for bubble haptics
    @State private var idleTouchPositions: [Int: CGPoint] = [:]
    @State private var idleTimers: [Int: Timer] = [:]
    @State private var lastIdleHapticTime: Date = .distantPast
    private let idleThreshold: CGFloat = 5.0 // Movement threshold to detect idle
    private let idleHapticInterval: TimeInterval = 0.3 // Haptic interval when idle
    
    // Three finger hold to go back
    @State private var threeIDs: Set<Int> = []
    @State private var threeStartPositions: [Int:CGPoint] = [:]
    @State private var threeHoldWork: DispatchWorkItem?
    @State private var threeFingersHold = false
    let threeMoveTolerance: CGFloat = 30
    
    // Timers
    private let starTimer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()
    private let bubbleTimer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()
    
    // Initializer to support inherited stars or create new ones
    init(inheritedStars: [Star] = [], initialSphereType: SphereType = .dawn) {
        if inheritedStars.isEmpty {
            // Create new stars if none inherited
            self._stars = State(initialValue: (0..<100).map { index in
                var star = Star()
                star.distance = CGFloat(index) * 5.0 + CGFloat.random(in: 1...20)
                return star
            })
        } else {
            // Use inherited stars from onboarding
            self._stars = State(initialValue: inheritedStars)
        }
        self._currentSphereType = State(initialValue: initialSphereType)
        self._selection = State(initialValue: initialSphereType.rawValue)
    }
    
    var body: some View {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        GeometryReader { geo in
            ZStack {
                // Background gradient - always visible
                currentSphereType.backgroundGradient
                    .ignoresSafeArea()
                
                // Animated stars - continue from onboarding or create new
                ForEach(stars) { star in
                    let starPosition = star.position(centerX: screenWidth/2, centerY: screenHeight/2)
                    
                    Circle()
                        .fill(Color.white.opacity(star.currentOpacity))
                        .frame(width: star.currentSize, height: star.currentSize)
                        .position(starPosition)
                        .blur(radius: star.distance < 50 ? 0.5 : 0)
                }
                
                if !isExpanded {
                    // Sphere selection mode
                    VStack {
                        Spacer()
                        
                        TabView(selection: $selection) {
                            ForEach(SphereType.allCases, id: \.rawValue) { sphereType in
                                VStack(spacing: 40) {
                                    GlowingSphereView(
                                        sphereType: sphereType,
                                        isActive: currentSphereType == sphereType,
                                        scale: $sphereScale,
                                        glowIntensity: $sphereGlowIntensity,
                                        breathingPhase: currentSphereType == sphereType ? sphereBreathingPhase : 0,
                                        useCustomBreathing: currentSphereType == sphereType && quickTapBreathing
                                    )
                                    .gesture(createSphereGesture(for: sphereType))
                                    
                                    SphereLabelView(
                                        sphereType: sphereType,
                                        isExpanded: isExpanded
                                    )
                                }
                                .tag(sphereType.rawValue)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .frame(height: geo.size.height * 0.6)
                        
                        // Star burst effect overlay
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
                    .transition(.scale.combined(with: .opacity))
                    
                } else {
                    // Expanded bubble mode
                    ZStack {
                        // Multitouch tracker
                        MultiTouchView(
                            onChange: { newTouches in
                                handleTouchChange(newTouches)
                            },
                            isArmed: { threeFingersHold },
                            onRight: {
                                // Three finger swipe right to go back
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    isExpanded = false
                                    bubbleManager.clearAll()
                                    touches.removeAll()
                                    threeFingersHold = false
                                    sphereScale = 1.0
                                    sphereGlowIntensity = AnimationConstants.sphereGlowIntensity
                                    // Clean up idle timers
                                    cleanupIdleDetection()
                                }
                                HapticManager.selection()
                            }
                        )
                        .ignoresSafeArea()
                        
                        // Animated bubbles
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
                        
                        // Instructions overlay
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
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.1).combined(with: .opacity),
                        removal: .scale(scale: 1.5).combined(with: .opacity)
                    ))
                }
            }
            .onAppear {
                // Only initialize stars if they're empty (not inherited)
                if stars.isEmpty {
                    initializeStars()
                }
                currentSphereType = SphereType(rawValue: selection) ?? .dawn
            }
            .onChange(of: selection) { newValue in
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentSphereType = SphereType(rawValue: newValue) ?? .dawn
                }
            }
            .onReceive(starTimer) { _ in
                updateStars()
            }
            .onReceive(bubbleTimer) { _ in
                if isExpanded {
                    bubbleManager.updatePhysics()
                    // Check for idle bubble collisions
                    checkIdleBubbleCollisions()
                }
                // Update star burst
                updateSelectionBurst()
                // Update breathing phase for quick tap
                if quickTapBreathing {
                    sphereBreathingPhase += 0.15
                    if sphereBreathingPhase > .pi * 2 {
                        sphereBreathingPhase = 0
                        quickTapBreathing = false
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            sphereScale = 1.0
                        }
                    }
                }
            }
            .onDisappear {
                cleanupIdleDetection()
            }
        }
        .navigationBarBackButtonHidden()
    }
    
    // MARK: - Sphere Gesture
    private func createSphereGesture(for sphereType: SphereType) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                if !isPressing {
                    isPressing = true
                    
                    // Initial haptic and animation
                    triggerHaptic(for: sphereType.hapticID)
                    
                    // Quick tap breathing effect
                    quickTapBreathing = true
                    sphereBreathingPhase = 0
                    
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0)) {
                        sphereScale = 0.85
                        sphereGlowIntensity = 1.3
                    }
                    
                    // Breathing animation synced with haptic
                    withAnimation(.easeInOut(duration: 0.5)) {
                        sphereScale = 0.9
                    }
                    
                    // Hold to expand - same animation as onboarding but with star burst
                    let work = DispatchWorkItem {
                        print("Expanding sphere \(sphereType.name)")
                        
                        // Save selection
                        selectedHaptic.selectedCircle = sphereType.hapticID
                        selectedHaptic.selectedColor = sphereType.baseColor
                        
                        // Success haptic
                        HapticManager.notification(.success)
                        
                        // Create star burst effect
                        self.createSelectionStarBurst(for: sphereType)
                        
                        // Shrink sphere like onboarding, then expand mode
                        withAnimation(.easeIn(duration: 0.3)) {
                            sphereScale = 0.1
                        }
                        
                        // Wait for shrink, then expand to bubble mode
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                self.isExpanded = true
                                self.sphereScale = 1.0
                                self.quickTapBreathing = false
                            }
                        }
                    }
                    holdWork = work
                    DispatchQueue.main.asyncAfter(deadline: .now() + AnimationConstants.sphereHoldDuration, execute: work)
                    
                } else {
                    // Continuous haptic while holding
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
                
                // If quick tap (not expanded), continue breathing animation
                if !isExpanded && !quickTapBreathing {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        sphereScale = 1.0
                        sphereGlowIntensity = AnimationConstants.sphereGlowIntensity
                    }
                }
            }
    }
    
    // MARK: - Star Burst Effect for Selection
    private func createSelectionStarBurst(for sphereType: SphereType) {
        let screenWidth = UIScreen.main.bounds.width
        let centerX = screenWidth / 2
        let centerY = UIScreen.main.bounds.height * 0.4 // Approximate sphere position
        
        selectionBurstBubbles = []
        
        // Create 5-pointed star burst pattern
        let starPoints = 5
        
        // Main star rays
        for point in 0..<starPoints {
            let pointAngle = Double(point) * (2 * .pi / Double(starPoints))
            
            // Multiple bubbles per ray for fuller effect
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
        
        // Additional radial particles
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
        
        // Start burst animation
        withAnimation(.easeOut(duration: 0.2)) {
            showSelectionBurst = true
        }
        
        // Hide burst after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showSelectionBurst = false
            selectionBurstBubbles.removeAll()
        }
    }
    
    // MARK: - Update Selection Burst
    private func updateSelectionBurst() {
        guard showSelectionBurst else { return }
        
        for i in selectionBurstBubbles.indices {
            var burst = selectionBurstBubbles[i]
            
            // Update position
            burst.position.x += burst.velocity.dx * 0.016
            burst.position.y += burst.velocity.dy * 0.016
            
            // Fade out
            burst.opacity *= 0.97
            
            // Slow down
            burst.velocity.dx *= 0.99
            burst.velocity.dy *= 0.99
            
            selectionBurstBubbles[i] = burst
        }
        
        // Remove faded bubbles
        selectionBurstBubbles.removeAll { $0.opacity < 0.05 }
    }
    
    // MARK: - Touch Handling for Expanded Mode
    private func handleTouchChange(_ newTouches: [Int: CGPoint]) {
        let previousTouches = touches
        touches = newTouches
        bubbleManager.updateTouches(newTouches, sphereType: currentSphereType)
        
        let now = Date()
        let screenHeight = UIScreen.main.bounds.height
        
        // Process each touch
        for (id, point) in newTouches {
            // Check if touch moved or is idle
            if let previousPoint = previousTouches[id] {
                let dx = point.x - previousPoint.x
                let dy = point.y - previousPoint.y
                let movement = sqrt(dx*dx + dy*dy)
                
                if movement < idleThreshold {
                    // Touch is idle or barely moving
                    if idleTouchPositions[id] == nil {
                        // Just became idle
                        idleTouchPositions[id] = point
                        startIdleHapticTimer(for: id, at: point)
                    }
                } else {
                    // Touch is moving
                    stopIdleHapticTimer(for: id)
                    idleTouchPositions.removeValue(forKey: id)
                    
                    // Play movement haptics - use selected sphere haptics only
                    if now.timeIntervalSince(lastTimes[id] ?? .distantPast) > AnimationConstants.hapticInterval {
                        lastTimes[id] = now
                        
                        // Just play the selected sphere haptic based on vertical position
                        if let a = area(for: point.y, totalHeight: screenHeight) {
                            triggerHapticByCircle(for: currentSphereType.hapticID, area: a)
                        }
                    }
                }
            } else {
                // New touch
                idleTouchPositions[id] = point
                startIdleHapticTimer(for: id, at: point)
            }
        }
        
        // Clean up removed touches
        let removedTouches = Set(previousTouches.keys).subtracting(Set(newTouches.keys))
        for id in removedTouches {
            stopIdleHapticTimer(for: id)
            idleTouchPositions.removeValue(forKey: id)
            lastTimes.removeValue(forKey: id)
        }
        
        // Three finger hold detection
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
        // Cancel existing timer if any
        stopIdleHapticTimer(for: touchID)
        
        // Create repeating timer for idle haptics
        let timer = Timer.scheduledTimer(withTimeInterval: idleHapticInterval, repeats: true) { _ in
            self.playIdleHaptic(for: touchID, at: point)
        }
        idleTimers[touchID] = timer
        
        // Play initial haptic immediately
        playIdleHaptic(for: touchID, at: point)
    }
    
    private func stopIdleHapticTimer(for touchID: Int) {
        idleTimers[touchID]?.invalidate()
        idleTimers.removeValue(forKey: touchID)
    }
    
    private func playIdleHaptic(for touchID: Int, at point: CGPoint) {
        // Check if finger is on a bubble
        for bubble in bubbleManager.touchBubbles {
            let dx = point.x - bubble.position.x
            let dy = point.y - bubble.position.y
            let distance = sqrt(dx*dx + dy*dy)
            
            if distance <= bubble.currentSize / 2 {
                // Finger is idle on a bubble
                let dir = direction(for: point, in: UIScreen.main.bounds)
                playDirectionalBubbleHaptic(dir)
                return
            }
        }
    }
    
    private func checkIdleBubbleCollisions() {
        // Check idle touches against current bubble positions
        for (touchID, point) in idleTouchPositions {
            // Bubbles may have moved, so check collision again
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
            
            // If idle touch moved off bubble, stop its timer
            if !isOnBubble && idleTimers[touchID] != nil {
                stopIdleHapticTimer(for: touchID)
                // Restart timer in case it moves onto another bubble
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
    
    // MARK: - Direction helper
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
            }
        }
    }
    
    // MARK: - Haptic Functions
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
            switch area {
            case 0: HapticManager.playAHAP(named: "dawn")
            case 1: HapticManager.playAHAP(named: "dawn")
            case 2: HapticManager.playAHAP(named: "dawn")
            default: break
            }
        case "circle1":
            switch area {
            case 0: HapticManager.playAHAP(named: "twilight")
            case 1: HapticManager.playAHAP(named: "twilight")
            case 2: HapticManager.playAHAP(named: "twilight")
            default: break
            }
        case "circle2":
            switch area {
            case 0: HapticManager.playAHAP(named: "reverie")
            case 1: HapticManager.playAHAP(named: "reverie")
            case 2: HapticManager.playAHAP(named: "reverie")
            default: break
            }
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

#Preview {
    MainMenuView()
        .environmentObject(SelectedHaptic())
}
