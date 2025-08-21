//
//  MainMenuView.swift
//  test_haptics
//
//  Created by Utari Dyani Laksmi on 14/08/25.
//

//anjay mabar

import SwiftUI

// MARK: - Star Model for Animation
struct Star: Identifiable {
    let id = UUID()
    var angle: CGFloat
    var distance: CGFloat
    var speed: CGFloat
    var baseSize: CGFloat
    
    init() {
        self.angle = CGFloat.random(in: 0...(2 * .pi))
        self.distance = 1.0
        self.speed = CGFloat.random(in: 50...150)
        self.baseSize = CGFloat.random(in: 0.5...2.0)
    }
    
    func position(centerX: CGFloat, centerY: CGFloat) -> CGPoint {
        return CGPoint(
            x: centerX + cos(angle) * distance,
            y: centerY + sin(angle) * distance
        )
    }
    
    var currentSize: CGFloat {
        return baseSize * min(distance / 100, 3.0)
    }
    
    var currentOpacity: Double {
        let maxDistance: CGFloat = 400
        let opacity = min(distance / maxDistance, 1.0)
        return Double(max(0.1, opacity))
    }
}

// MARK: - Bubble Model
struct TouchBubble: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGVector
    var baseSize: CGFloat = 60
    var breathingPhase: CGFloat = 0
    var breathingSpeed: CGFloat = 1.0
    var opacity: Double = 0.6
    var color: Color = .red
    var touchID: Int
    
    var currentSize: CGFloat {
        let breathingMultiplier: CGFloat = 0.3
        let breathing = sin(breathingPhase) * breathingMultiplier + 1.0
        return baseSize * breathing
    }
    
    var radius: CGFloat { currentSize / 2 }
}

struct MainMenuView: View {
    @EnvironmentObject var selectedHaptic: SelectedHaptic
    
    // Circle selection state
    @State private var selection = 0
    @State private var isPressing = false
    @State private var holdWork: DispatchWorkItem? = nil
    @State private var lastHapticTime: Date = .distantPast
    let hapticInterval: TimeInterval = 0.2
    
    // Expanded mode state
    @State private var isExpanded = false
    @State private var expandedColor: Color = .red
    @State private var expandedCircle: String = "circle0"
    
    // Star animation
    @State private var stars: [Star] = []
    private let starCount = 100
    
    // Bubble animation for expanded mode
    @State private var touchBubbles: [TouchBubble] = []
    @State private var touches: [Int: CGPoint] = [:]
    @State private var lastTimes: [Int: Date] = [:]
    
    // Three finger hold to go back
    @State private var threeIDs: Set<Int> = []
    @State private var threeStartPositions: [Int:CGPoint] = [:]
    @State private var threeHoldWork: DispatchWorkItem?
    @State private var threeFingersHold = false
    let threeHoldDuration: TimeInterval = 2.0
    let threeMoveTolerance: CGFloat = 30
    
    // Physics constants for bubbles
    private let bubbleCount = 8
    private let pullStrength: CGFloat = 1.2
    private let damping: CGFloat = 0.88
    private let maxSpeed: CGFloat = 12
    private let orbitSpeed: CGFloat = 0.7
    
    // Timers
    private let starTimer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()
    private let bubbleTimer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        GeometryReader { geo in
            ZStack {
                // Background gradient
                backgroundGradient
                    .ignoresSafeArea()
                
                if !isExpanded {
                    // Circle selection mode with stars
                    ZStack {
                        // Animated stars
                        ForEach(stars) { star in
                            let starPosition = star.position(centerX: screenWidth/2, centerY: screenHeight/2)
                            
                            Circle()
                                .fill(Color.white.opacity(star.currentOpacity))
                                .frame(width: star.currentSize, height: star.currentSize)
                                .position(starPosition)
                                .blur(radius: star.distance < 50 ? 0.5 : 0)
                        }
                        
                        // Circle selection
                        TabView(selection: $selection) {
                            ForEach(0..<3) { index in
                                Circle()
                                    .fill(circleColor(for: index))
                                    .frame(width: geo.size.width/2, height: geo.size.height/3)
                                    .tag(index)
                                    .contentShape(Circle())
                                    .gesture(createCircleGesture(for: index))
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .position(x: screenWidth/2, y: screenHeight/2)
                    }
                    .transition(.scale.combined(with: .opacity))
                    
                } else {
                    // Expanded bubble mode
                    ZStack {
                        Color.white.opacity(0.1)
                            .ignoresSafeArea()
                        
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
                                    touchBubbles.removeAll()
                                    touches.removeAll()
                                    threeFingersHold = false
                                }
                                HapticManager.selection()
                            }
                        )
                        .ignoresSafeArea()
                        
                        // Animated bubbles
                        ForEach(touchBubbles) { bubble in
                            Circle()
                                .fill(bubble.color.opacity(bubble.opacity))
                                .frame(width: bubble.currentSize, height: bubble.currentSize)
                                .position(bubble.position)
                                .blur(radius: 6)
                                .shadow(color: bubble.color.opacity(0.6), radius: 8)
                                .allowsHitTesting(false)
                                .animation(.easeOut(duration: 0.1), value: bubble.position)
                        }
                        
                        // Instructions overlay
                        if threeFingersHold {
                            VStack {
                                Text("Swipe right to go back")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .background(Color.black.opacity(0.7))
                                    .cornerRadius(10)
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
                initializeStars()
            }
            .onReceive(starTimer) { _ in
                if !isExpanded {
                    updateStars()
                }
            }
            .onReceive(bubbleTimer) { _ in
                if isExpanded {
                    updateBubblePhysics()
                }
            }
        }
        .navigationBarBackButtonHidden()
    }
    
    // MARK: - Circle Management
    private func circleColor(for index: Int) -> Color {
        switch index {
        case 0: return .red
        case 1: return .blue
        case 2: return .green
        default: return .gray
        }
    }
    
    private func createCircleGesture(for index: Int) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in
                if !isPressing {
                    isPressing = true
                    let color = circleColor(for: index)
                    let circle = "circle\(index)"
                    
                    // Initial haptic
                    triggerHaptic(for: circle)
                    
                    // Hold for 3 seconds to expand
                    let work = DispatchWorkItem {
                        print("Expanding circle \(index)")
                        
                        // Save selection
                        selectedHaptic.selectedCircle = circle
                        selectedHaptic.selectedColor = color
                        expandedColor = color
                        expandedCircle = circle
                        
                        // Haptic feedback
                        HapticManager.notification(.success)
                        
                        // Expand with animation
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                            isExpanded = true
                        }
                    }
                    holdWork = work
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: work)
                    
                } else {
                    // Continuous haptic while holding
                    let now = Date()
                    if now.timeIntervalSince(lastHapticTime) > hapticInterval {
                        lastHapticTime = now
                        triggerHaptic(for: "circle\(index)")
                    }
                }
            }
            .onEnded { _ in
                isPressing = false
                holdWork?.cancel()
                holdWork = nil
            }
    }
    
    // MARK: - Touch Handling for Expanded Mode
    private func handleTouchChange(_ newTouches: [Int: CGPoint]) {
        touches = newTouches
        updateBubblesForTouches(newTouches)
        
        let now = Date()
        let screenHeight = UIScreen.main.bounds.height
        
        // Haptic feedback for touches
        for (id, point) in newTouches {
            if now.timeIntervalSince(lastTimes[id] ?? .distantPast) > hapticInterval {
                lastTimes[id] = now
                
                if let a = area(for: point.y, totalHeight: screenHeight) {
                    triggerHapticByCircle(for: expandedCircle, area: a)
                }
            }
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
                DispatchQueue.main.asyncAfter(deadline: .now() + threeHoldDuration, execute: work)
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
    
    // MARK: - Bubble Management
    private func updateBubblesForTouches(_ newTouches: [Int: CGPoint]) {
        let currentTouchIDs = Set(newTouches.keys)
        let bubbleTouchIDs = Set(touchBubbles.map { $0.touchID })
        
        // Remove bubbles for ended touches
        let touchesToRemove = bubbleTouchIDs.subtracting(currentTouchIDs)
        if !touchesToRemove.isEmpty {
            withAnimation(.easeOut(duration: 0.3)) {
                touchBubbles.removeAll { touchesToRemove.contains($0.touchID) }
            }
        }
        
        // Add bubbles for new touches (limit to first 2)
        let newTouchIDs = currentTouchIDs.subtracting(bubbleTouchIDs)
        for touchID in Array(newTouchIDs.prefix(2)) {
            if let touchPosition = newTouches[touchID] {
                spawnBubblesForTouch(touchID: touchID, position: touchPosition)
            }
        }
    }
    
    private func spawnBubblesForTouch(touchID: Int, position: CGPoint) {
        for _ in 0..<bubbleCount {
            let angle = Double.random(in: 0..<2 * .pi)
            let burstSpeed = CGFloat.random(in: 8...15)
            let initialVelocity = CGVector(
                dx: cos(Double(angle)) * burstSpeed,
                dy: sin(Double(angle)) * burstSpeed
            )
            
            let bubble = TouchBubble(
                position: position,
                velocity: initialVelocity,
                baseSize: CGFloat.random(in: 50...70),
                breathingPhase: CGFloat.random(in: 0...2 * .pi),
                breathingSpeed: CGFloat.random(in: 0.8...1.5),
                opacity: Double.random(in: 0.4...0.8),
                color: expandedColor,
                touchID: touchID
            )
            
            touchBubbles.append(bubble)
        }
    }
    
    private func updateBubblePhysics() {
        guard !touchBubbles.isEmpty else { return }
        
        for i in touchBubbles.indices {
            var bubble = touchBubbles[i]
            
            // Update breathing
            bubble.breathingPhase += 0.1 * bubble.breathingSpeed
            
            if let touchPosition = touches[bubble.touchID] {
                // Calculate forces
                let gravityForce = calculateGravityForce(from: bubble.position, to: touchPosition)
                let orbitalForce = calculateOrbitalForce(from: bubble.position, around: touchPosition)
                let chaosForce = CGVector(
                    dx: CGFloat.random(in: -0.8...0.8),
                    dy: CGFloat.random(in: -0.8...0.8)
                )
                let repulsionForce = calculateBubbleRepulsion(for: bubble, in: touchBubbles)
                
                // Apply forces
                bubble.velocity.dx += gravityForce.dx * 0.7 + orbitalForce.dx * 0.2 + chaosForce.dx + repulsionForce.dx * 0.3
                bubble.velocity.dy += gravityForce.dy * 0.7 + orbitalForce.dy * 0.2 + chaosForce.dy + repulsionForce.dy * 0.3
                
                // Damping
                bubble.velocity.dx *= damping
                bubble.velocity.dy *= damping
                
                // Speed limit
                let speed = hypot(bubble.velocity.dx, bubble.velocity.dy)
                if speed > maxSpeed {
                    let scale = maxSpeed / speed
                    bubble.velocity.dx *= scale
                    bubble.velocity.dy *= scale
                }
                
                // Update position
                let screenBounds = UIScreen.main.bounds
                bubble.position.x = max(bubble.radius, min(screenBounds.width - bubble.radius, bubble.position.x + bubble.velocity.dx))
                bubble.position.y = max(bubble.radius, min(screenBounds.height - bubble.radius, bubble.position.y + bubble.velocity.dy))
            }
            
            touchBubbles[i] = bubble
        }
    }
    
    // MARK: - Physics Helpers
    private func calculateGravityForce(from position: CGPoint, to center: CGPoint) -> CGVector {
        let dx = center.x - position.x
        let dy = center.y - position.y
        let distance = max(1, hypot(dx, dy))
        
        return CGVector(
            dx: (dx / distance) * pullStrength,
            dy: (dy / distance) * pullStrength
        )
    }
    
    private func calculateOrbitalForce(from position: CGPoint, around center: CGPoint) -> CGVector {
        let dx = position.x - center.x
        let dy = position.y - center.y
        let distance = max(1, hypot(dx, dy))
        
        return CGVector(
            dx: -dy / distance * orbitSpeed,
            dy: dx / distance * orbitSpeed
        )
    }
    
    private func calculateBubbleRepulsion(for targetBubble: TouchBubble, in allBubbles: [TouchBubble]) -> CGVector {
        var repulsionForce = CGVector.zero
        
        for bubble in allBubbles {
            guard bubble.id != targetBubble.id else { continue }
            
            let dx = targetBubble.position.x - bubble.position.x
            let dy = targetBubble.position.y - bubble.position.y
            let distance = hypot(dx, dy)
            
            let repulsionRadius: CGFloat = 80
            if distance < repulsionRadius && distance > 1 {
                let normalizedDx = dx / distance
                let normalizedDy = dy / distance
                let strength = 0.5 * (repulsionRadius - distance) / repulsionRadius
                
                repulsionForce.dx += normalizedDx * strength
                repulsionForce.dy += normalizedDy * strength
            }
        }
        
        return repulsionForce
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
    
    func triggerHaptic(for circle: String) {
        switch circle {
        case "circle0":
            HapticManager.playAHAP(named: "bubble")
        case "circle1":
            HapticManager.playAHAP(named: "heavy50")
        case "circle2":
            HapticManager.playAHAP(named: "heavy75")
        default:
            break
        }
    }
    
    func triggerHapticByCircle(for circle: String, area: Int) {
        switch circle {
        case "circle0":
            switch area {
            case 0: HapticManager.playAHAP(named: "bubble")
            case 1: HapticManager.playAHAP(named: "bubble_75")
            case 2: HapticManager.playAHAP(named: "bubble_50")
            default: break
            }
        case "circle1":
            switch area {
            case 0: HapticManager.playAHAP(named: "heavy50")
            case 1: HapticManager.playAHAP(named: "heavy50_75")
            case 2: HapticManager.playAHAP(named: "heavy50_50")
            default: break
            }
        case "circle2":
            switch area {
            case 0: HapticManager.playAHAP(named: "heavy75")
            case 1: HapticManager.playAHAP(named: "heavy75_75")
            case 2: HapticManager.playAHAP(named: "heavy75_50")
            default: break
            }
        default:
            break
        }
    }
    
    // MARK: - Background Gradient
    private var backgroundGradient: some View {
        Group {
            if isExpanded {
                // White background for bubble mode
                Color.white
            } else {
                // Dynamic gradient based on selection
                if selection == 0 {
                    LinearGradient(
                        stops: [
                            Gradient.Stop(color: Color(red: 0.1, green: 0.1, blue: 0.1), location: 0.00),
                            Gradient.Stop(color: Color(red: 1, green: 0.76, blue: 0.32), location: 1.00),
                        ],
                        startPoint: UnitPoint(x: 0.1, y: -0.02),
                        endPoint: UnitPoint(x: 1.18, y: 3.00)
                    )
                } else if selection == 1 {
                    LinearGradient(
                        stops: [
                            Gradient.Stop(color: Color(red: 0.05, green: 0.05, blue: 0.05), location: 0.00),
                            Gradient.Stop(color: Color(red: 0.23, green: 0.07, blue: 0.4).opacity(0.7), location: 0.57),
                            Gradient.Stop(color: Color(red: 1, green: 0.73, blue: 0.9).opacity(0.9), location: 1.00),
                        ],
                        startPoint: UnitPoint(x: 0.1, y: -0.02),
                        endPoint: UnitPoint(x: 1.18, y: 2.00)
                    )
                } else {
                    LinearGradient(
                        stops: [
                            Gradient.Stop(color: Color(red: 0.1, green: 0.1, blue: 0.1), location: 0.00),
                            Gradient.Stop(color: Color(red: 0, green: 0.5, blue: 0.8).opacity(0.8), location: 1),
                        ],
                        startPoint: UnitPoint(x: 0.1, y: -0.02),
                        endPoint: UnitPoint(x: 1.3, y: 2)
                    )
                }
            }
        }
    }
}

#Preview {
    MainMenuView()
        .environmentObject(SelectedHaptic())
}
