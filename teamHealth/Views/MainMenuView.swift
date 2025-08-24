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
    var idleBreathingPhase: CGFloat = 0 // Kept for compatibility, but not used in this design
    var useCustomBreathing: Bool = false // Kept for compatibility, but not used in this design
    
<<<<<<< HEAD
    // Internal state for the sphere's own animations
    @State private var pulseAnimation = false
    @State private var rotationAngle: Double = 0
=======
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
    @State private var naturalBreathingPhase: CGFloat = 0
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
    
    // Carousel state for infinite scrolling
    @State private var dragOffset: CGFloat = 0
    @State private var currentIndex: Int = 0
    
    @StateObject private var soundManager = SoundManager.shared
    
    // Timers
    private let starTimer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()
    private let bubbleTimer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()
    
    // Initializer to support inherited stars or create new ones
    init(inheritedStars: [Star] = [], initialSphereType: SphereType = .dawn) {
        if inheritedStars.isEmpty {
            self._stars = State(initialValue: (0..<100).map { index in
                var star = Star()
                star.distance = CGFloat(index) * 5.0 + CGFloat.random(in: 1...20)
                return star
            })
        } else {
            self._stars = State(initialValue: inheritedStars)
        }
        self._currentSphereType = State(initialValue: initialSphereType)
        self._selection = State(initialValue: initialSphereType.rawValue)
        self._currentIndex = State(initialValue: initialSphereType.rawValue)
    }
    
    var body: some View {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        GeometryReader { geo in
            ZStack {
                currentSphereType.backgroundGradient
                    .ignoresSafeArea()
                
                VStack {
                    HStack {
                        Spacer()
                        SoundToggleButton(color: currentSphereType.baseColor)
                            .padding(.trailing, 20)
                            .padding(.top, 50)
                            .animation(.easeInOut(duration: 0.3), value: currentSphereType)
                    }
                    Spacer()
                }
                .zIndex(100)
                
                ForEach(stars) { star in
                    let starPosition = star.position(centerX: screenWidth/2, centerY: screenHeight/2)
                    
                    Circle()
                        .fill(Color.white.opacity(star.currentOpacity))
                        .frame(width: star.currentSize, height: star.currentSize)
                        .position(starPosition)
                        .blur(radius: star.distance < 50 ? 0.5 : 0)
                }
                
                if !isExpanded {
                    VStack {
                        Spacer()
                        
                        SphereCarouselView(
                            currentIndex: $currentIndex,
                            dragOffset: $dragOffset,
                            currentSphereType: $currentSphereType,
                            selection: $selection,
                            sphereScale: $sphereScale,
                            sphereGlowIntensity: $sphereGlowIntensity,
                            sphereBreathingPhase: sphereBreathingPhase,
                            naturalBreathingPhase: naturalBreathingPhase,
                            quickTapBreathing: quickTapBreathing,
                            isExpanded: isExpanded,
                            createSphereGesture: createSphereGesture
                        )
                        .frame(height: geo.size.height)
                        
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
                    ZStack {
                        MultiTouchView(
                            onChange: { newTouches in
                                handleTouchChange(newTouches)
                            },
                            isArmed: { threeFingersHold },
                            onRight: {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    isExpanded = false
                                    bubbleManager.clearAll()
                                    touches.removeAll()
                                    threeFingersHold = false
                                    sphereScale = 1.0
                                    sphereGlowIntensity = AnimationConstants.sphereGlowIntensity
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
                        
                        // Cursors that follow each finger with an offset
                        ForEach(touches.map { TouchPoint(id: $0.key, position: $0.value) }) { touchPoint in
                            TouchCursorView(color: currentSphereType.baseColor)
                                .position(x: touchPoint.position.x, y: touchPoint.position.y - 45) // Apply vertical offset
                                .transition(.opacity.combined(with: .scale))
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
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.1).combined(with: .opacity),
                        removal: .scale(scale: 1.5).combined(with: .opacity)
                    ))
                }
            }
            .onAppear {
                if stars.isEmpty {
                    initializeStars()
                }
                currentSphereType = SphereType(rawValue: selection) ?? .dawn
                currentIndex = selection
                soundManager.playTrack(soundManager.trackName(for: currentSphereType))
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
            .onChange(of: currentSphereType) { newType in
                soundManager.playTrack(soundManager.trackName(for: newType))
            }
            .onReceive(starTimer) { _ in
                updateStars()
            }
            .onReceive(bubbleTimer) { _ in
                naturalBreathingPhase += 0.03
                
                if isExpanded {
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
    
    private func createSphereGesture(for sphereType: SphereType) -> AnyGesture<DragGesture.Value> {
        return AnyGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressing {
                        isPressing = true
                        
                        triggerHaptic(for: sphereType.hapticID)
                        
                        quickTapBreathing = true
                        sphereBreathingPhase = naturalBreathingPhase
                        
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0)) {
                            sphereScale = 0.85
                            sphereGlowIntensity = 1.3
                        }
                        
                        let work = DispatchWorkItem {
                            print("Expanding sphere \(sphereType.name)")
                            
                            selectedHaptic.selectedCircle = sphereType.hapticID
                            selectedHaptic.selectedColor = sphereType.baseColor
                            
                            HapticManager.notification(.success)
                            
                            self.isExpanded = true
                        }
                        holdWork = work
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: work)
                        
                    } else {
                        let now = Date()
                        if now.timeIntervalSince(lastHapticTime) > 0.2 {
                            lastHapticTime = now
                            triggerHaptic(for: sphereType.hapticID)
                        }
                    }
                }
                .onEnded { _ in
                    isPressing = false
                    holdWork?.cancel()
                    holdWork = nil
                    
                    if !isExpanded && !quickTapBreathing {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0)) {
                            sphereScale = 1.0
                            sphereGlowIntensity = AnimationConstants.sphereGlowIntensity
                        }
                    }
                }
        )
    }
    
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
    
    // MainMenuView.swift - Fixed handleTouchChange and haptic functions
    

    private func handleTouchChange(_ newTouches: [Int: CGPoint]) {
        let previousTouches = self.touches
        self.touches = newTouches
        
        // Create a new dictionary with the offset applied for the physics
        var offsetTouches: [Int: CGPoint] = [:]
        for (id, point) in newTouches {
            offsetTouches[id] = CGPoint(x: point.x, y: point.y - 45)
        }
        
        bubbleManager.updateTouches(offsetTouches, sphereType: currentSphereType)
        
        let now = Date()
        let screenHeight = UIScreen.main.bounds.height
        
        for (id, point) in newTouches {
            if let previousPoint = previousTouches[id] {
                let dx = point.x - previousPoint.x
                let dy = point.y - previousPoint.y
                let movement = sqrt(dx*dx + dy*dy)
                
                if movement < idleThreshold {
                    // Touch is idle - store position if not already stored
                    if idleTouchPositions[id] == nil {
                        idleTouchPositions[id] = point
                        // Don't start timer immediately - let checkIdleBubbleCollisions handle it
                    }
                } else {
                    // Touch is moving - clear idle state
                    stopIdleHapticTimer(for: id)
                    idleTouchPositions.removeValue(forKey: id)
                    
                    // Play movement haptic
                    if now.timeIntervalSince(lastTimes[id] ?? .distantPast) > AnimationConstants.hapticInterval {
                        lastTimes[id] = now
                        
                        if let a = area(for: point.y, totalHeight: screenHeight) {
                            triggerHapticByCircle(for: currentSphereType.hapticID, area: a)
                        }
                    }
                }
            } else {
                // New touch - store as idle initially
                idleTouchPositions[id] = point
                
                // Play initial haptic
                if let a = area(for: point.y, totalHeight: screenHeight) {
                    triggerHapticByCircle(for: currentSphereType.hapticID, area: a)
                }
            }
        }
        
        // Handle removed touches
        let removedTouches = Set(previousTouches.keys).subtracting(Set(newTouches.keys))
        for id in removedTouches {
            stopIdleHapticTimer(for: id)
            idleTouchPositions.removeValue(forKey: id)
            lastTimes.removeValue(forKey: id)
        }
        
        // Three finger hold logic remains the same...
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
    
    private func isTouchOnBubble(_ point: CGPoint) -> Bool {
        for bubble in bubbleManager.touchBubbles {
            let dx = point.x - bubble.position.x
            let dy = point.y - bubble.position.y
            let distance = sqrt(dx*dx + dy*dy)
            
            if distance <= bubble.currentSize / 2 + 5 {
                return true
            }
        }
        return false
    }
    
    
    private func startIdleHapticTimer(for touchID: Int, at point: CGPoint) {
        stopIdleHapticTimer(for: touchID)
        
        // Check immediately if we're on a bubble
        let offsetPoint = CGPoint(x: point.x, y: point.y - 45)
        if isTouchOnBubble(offsetPoint) {
            playIdleHaptic(for: touchID, at: point)
        }
        
        // Start repeating timer
        let timer = Timer.scheduledTimer(withTimeInterval: idleHapticInterval, repeats: true) { _ in
            self.playIdleHaptic(for: touchID, at: point)
        }
        idleTimers[touchID] = timer
    }
    
    private func stopIdleHapticTimer(for touchID: Int) {
        idleTimers[touchID]?.invalidate()
        idleTimers.removeValue(forKey: touchID)
    }
    
    private func playIdleHaptic(for touchID: Int, at point: CGPoint) {
        // Apply the same offset as bubbles use
        let offsetPoint = CGPoint(x: point.x, y: point.y - 45)
        
        for bubble in bubbleManager.touchBubbles {
            let dx = offsetPoint.x - bubble.position.x
            let dy = offsetPoint.y - bubble.position.y
            let distance = sqrt(dx*dx + dy*dy)
            
            // Check if touch is within bubble radius (with a small tolerance)
            if distance <= bubble.currentSize / 2 + 5 {
                let dir = direction(for: point, in: UIScreen.main.bounds)
                playDirectionalBubbleHaptic(dir)
                return
            }
        }
    }
    
    
    private func checkIdleBubbleCollisions() {
        for (touchID, point) in idleTouchPositions {
            // Apply offset to match bubble positions
            let offsetPoint = CGPoint(x: point.x, y: point.y - 45)
            let isOnBubble = isTouchOnBubble(offsetPoint)
            
            // If touch is on a bubble and we don't have a timer, start one
            if isOnBubble && idleTimers[touchID] == nil {
                startIdleHapticTimer(for: touchID, at: point)
            }
            // If touch is NOT on a bubble and we have a timer, stop it
            else if !isOnBubble && idleTimers[touchID] != nil {
                stopIdleHapticTimer(for: touchID)
            }
        }
    }
    
    private func cleanupIdleDetection() {
        for (id, _) in idleTimers {
            stopIdleHapticTimer(for: id)
        }
        idleTouchPositions.removeAll()
    }
    
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
        case "circle0":  // Dawn
            switch area {
            case 0: HapticManager.playAHAP(named: "dawn_75")     // Top - strongest
            case 1: HapticManager.playAHAP(named: "dawn_50")     // Middle - medium
            case 2: HapticManager.playAHAP(named: "dawn")        // Bottom - normal
            default: break
            }
        case "circle1":  // Twilight
            switch area {
            case 0: HapticManager.playAHAP(named: "twilight_75") // Top - strongest
            case 1: HapticManager.playAHAP(named: "twilight_50") // Middle - medium
            case 2: HapticManager.playAHAP(named: "twilight")    // Bottom - normal
            default: break
            }
        case "circle2":  // Reverie
            switch area {
            case 0: HapticManager.playAHAP(named: "reverie_75")  // Top - strongest
            case 1: HapticManager.playAHAP(named: "reverie_50")  // Middle - medium
            case 2: HapticManager.playAHAP(named: "reverie")     // Bottom - normal
            default: break
            }
        default:
            break
        }
    }
}

// MARK: - Touch Cursor View
struct TouchCursorView: View {
    let color: Color
>>>>>>> parent of a914068 (Update MainMenuView.swift)
    
    var body: some View {
        ZStack {
            // MARK: - Old Sphere Design
            
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
            
            // Main sphere
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
            .scaleEffect(scale) // Apply scaling from parent
            
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
                .scaleEffect(scale)
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
            // Note: If you have a constant for the glow intensity, you might need to re-add it.
            // Using a default of 0.8 for demonstration.
            let targetGlow = 0.8
            glowIntensity = glowIntensity == targetGlow ? 1.0 : targetGlow
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
