//
//  ResultScreenView.swift
//  teamHealth
//
//  Created by Utari Dyani Laksmi on 14/08/25.
//



import SwiftUI
import SwiftData
import CoreGraphics
import Foundation

// MARK: - Bubble Model for ResultScreenView
struct TouchBubble: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGVector
    var baseSize: CGFloat = 60 // Match original base size
    var breathingPhase: CGFloat = 0
    var breathingSpeed: CGFloat = 1.0
    var opacity: Double = 0.6
    var color: Color = .red
    var touchID: Int // Track which touch this bubble belongs to
    
    // Computed property for current size with breathing - EXACTLY like original
    var currentSize: CGFloat {
        let breathingMultiplier: CGFloat = 0.3 // Match original 30% size change
        let breathing = Foundation.sin(breathingPhase) * breathingMultiplier + 1.0
        return baseSize * breathing
    }
    
    var radius: CGFloat { currentSize / 2 }
}

struct ResultScreenView: View {
    @EnvironmentObject var hapticData: HapticData // no longer used
    @EnvironmentObject var selectedHaptic: SelectedHaptic
    
    // multitouch state
    @State private var touches: [Int: CGPoint] = [:]
    @State private var lastTimes: [Int: Date] = [:]
    @State private var holdThreeFingers = false
    let hapticInterval: TimeInterval = 0.2
    
    // Bubble animation state
    @State private var touchBubbles: [TouchBubble] = []
    @State private var screenBounds: CGRect = UIScreen.main.bounds
    
    // Physics constants for bubbles - Match original exactly
    private let bubbleCount = 8 // Match original bubble count
    private let pullStrength: CGFloat = 1.2 // Match original pull strength
    private let damping: CGFloat = 0.88 // Match original damping
    private let maxSpeed: CGFloat = 12 // Match original max active speed
    private let orbitSpeed: CGFloat = 0.7 // Match original orbit speed
    
    @State private var threeIDs: Set<Int> = []
    @State private var threeStartPositions: [Int:CGPoint] = [:]
    @State private var threeHoldWork: DispatchWorkItem?
    @State private var threeFingersHold = false
    @State private var fingerPosition = "red"
    let threeHoldDuration: TimeInterval = 2.0
    let threeMoveTolerance: CGFloat = 30
    
    @State private var backToMainMenu = false
    
    // Timer for bubble animation updates
    private let timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        let screenHeight = UIScreen.main.bounds.height
        
        NavigationStack {
            ZStack {
                // bg
                Color.white.ignoresSafeArea()
                
                // multitouch tracker (transparent, full screen)
                MultiTouchView(
                    onChange: { newTouches in
                        touches = newTouches
                        updateBubblesForTouches(newTouches)
                        
                        let circle = selectedHaptic.selectedCircle ?? "circle0"
                        let now = Date()
                        
                        for (id, point) in newTouches {
                            if now.timeIntervalSince(lastTimes[id] ?? .distantPast) > hapticInterval {
                                lastTimes[id] = now
                                
                                if let a = area(for: point.y, totalHeight: screenHeight) {
                                    triggerHapticByCircle(for: circle, area: a)
                                    print("yeay here")
                                }
                                else {
                                    print("not there yet")
                                }
                            }
                        }
                        
                        // 3 fingers hold logic
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
                                        self.threeFingersHold = true
                                        HapticManager.selection()
                                        print("3 fingers hold armed")
                                    }
                                }
                                threeHoldWork = work
                                DispatchQueue.main.asyncAfter(deadline: .now() + threeHoldDuration, execute: work)
                            }
                        } else {
                            threeHoldWork?.cancel(); threeHoldWork = nil
                            threeIDs = []
                            threeStartPositions = [:]
                            threeFingersHold = false
                        }
                    },
                    
                    isArmed: { threeFingersHold },
                    onRight: {
                        print("swipe right")
                        HapticManager.selection()
                        threeFingersHold = false
                        backToMainMenu = true
                    }
                )
                .ignoresSafeArea()
                
                // Animated bubbles instead of simple circles - Match original styling
                ForEach(touchBubbles) { bubble in
                    Circle()
                        .fill(bubble.color.opacity(bubble.opacity))
                        .frame(width: bubble.currentSize, height: bubble.currentSize)
                        .position(bubble.position)
                        .blur(radius: 6) // Match original blur radius
                        .shadow(color: bubble.color.opacity(0.6), radius: 8) // Match original shadow
                        .allowsHitTesting(false)
                        .animation(.easeOut(duration: 0.1), value: bubble.position)
                }
                
                if threeFingersHold {
                    let widthScreen = UIScreen.main.bounds.width
                    Text("Swipe right to go back")
                        .position(x:widthScreen/2, y:50)
                }
            }
            .ignoresSafeArea()
            .navigationBarBackButtonHidden(true)
            .navigationDestination(isPresented: $backToMainMenu) {
                MainMenuView()
            }
            .onReceive(timer) { _ in
                updateBubblePhysics()
            }
        }
    }
    
    // MARK: - Bubble Management
    private func updateBubblesForTouches(_ newTouches: [Int: CGPoint]) {
        let currentTouchIDs = Set(newTouches.keys)
        let bubbleTouchIDs = Set(touchBubbles.map { $0.touchID })
        
        // Remove bubbles for touches that no longer exist
        let touchesToRemove = bubbleTouchIDs.subtracting(currentTouchIDs)
        if !touchesToRemove.isEmpty {
            withAnimation(.easeOut(duration: 0.3)) {
                touchBubbles.removeAll { touchesToRemove.contains($0.touchID) }
            }
        }
        
        // Add bubbles for new touches (limit to first 2 touches)
        let newTouchIDs = currentTouchIDs.subtracting(bubbleTouchIDs)
        for touchID in Array(newTouchIDs.prefix(2)) {
            if let touchPosition = newTouches[touchID] {
                spawnBubblesForTouch(touchID: touchID, position: touchPosition)
            }
        }
        
        // Update existing bubble target positions
        for i in touchBubbles.indices {
            if let newPosition = newTouches[touchBubbles[i].touchID] {
                // Don't directly set position, let physics handle it
                // The bubbles will be attracted to the new touch position
            }
        }
    }
    
    private func spawnBubblesForTouch(touchID: Int, position: CGPoint) {
        let bubbleColor = selectedHaptic.selectedColor ?? .red
        
        // Create multiple bubbles around the touch point - EXACTLY like original
        for _ in 0..<bubbleCount {
            let angle = Double.random(in: 0..<2 * .pi)
            // Start all bubbles at the center point (like original)
            let bubblePosition = position
            
            // Give them strong initial burst velocity - Match original burst
            let burstSpeed = CGFloat.random(in: 8...15) // Match original burst speed range
            let initialVelocity = CGVector(
                dx: cos(angle) * burstSpeed,
                dy: sin(angle) * burstSpeed
            )
            
            let bubble = TouchBubble(
                position: bubblePosition,
                velocity: initialVelocity,
                baseSize: CGFloat.random(in: 50...70), // Match original size range
                breathingPhase: CGFloat.random(in: 0...2 * .pi), // Random starting phase
                breathingSpeed: CGFloat.random(in: 0.8...1.5), // Match original breathing speed range
                opacity: Double.random(in: 0.4...0.8), // Match original opacity range
                color: bubbleColor,
                touchID: touchID
            )
            
            touchBubbles.append(bubble)
        }
    }
    
    private func updateBubblePhysics() {
        guard !touchBubbles.isEmpty else { return }
        
        for i in touchBubbles.indices {
            var bubble = touchBubbles[i]
            
            // Update breathing animation - Match original speed
            bubble.breathingPhase += 0.1 * bubble.breathingSpeed // Match original breathing update rate
            
            // Get the current touch position for this bubble
            if let touchPosition = touches[bubble.touchID] {
                // Calculate attraction force toward touch position
                let gravityForce = calculateGravityForce(from: bubble.position, to: touchPosition)
                
                // Add orbital motion around the touch point
                let orbitalForce = calculateOrbitalForce(from: bubble.position, around: touchPosition)
                
                // Add chaotic movement for organic feel - Match original chaos
                let chaosStrength: CGFloat = 0.8 // Match original chaos strength
                let chaosForce = CGVector(
                    dx: CGFloat.random(in: -chaosStrength...chaosStrength),
                    dy: CGFloat.random(in: -chaosStrength...chaosStrength)
                )
                
                // Add bubble repulsion like original
                let repulsionForce = calculateBubbleRepulsion(for: bubble, in: touchBubbles)
                
                // Combine all forces with same weights as original
                bubble.velocity.dx += gravityForce.dx * 0.7 + orbitalForce.dx * 0.2 + chaosForce.dx + repulsionForce.dx * 0.3
                bubble.velocity.dy += gravityForce.dy * 0.7 + orbitalForce.dy * 0.2 + chaosForce.dy + repulsionForce.dy * 0.3
                
                // Apply damping - Match original
                bubble.velocity.dx *= damping
                bubble.velocity.dy *= damping
                
                // Limit velocity - Match original
                let speed = hypot(bubble.velocity.dx, bubble.velocity.dy)
                if speed > maxSpeed {
                    let scale = maxSpeed / speed
                    bubble.velocity.dx *= scale
                    bubble.velocity.dy *= scale
                }
                
                // Update position with bounds checking
                let newX = bubble.position.x + bubble.velocity.dx
                let newY = bubble.position.y + bubble.velocity.dy
                
                let screenWidth = UIScreen.main.bounds.width
                let screenHeight = UIScreen.main.bounds.height
                
                bubble.position.x = max(bubble.radius, min(screenWidth - bubble.radius, newX))
                bubble.position.y = max(bubble.radius, min(screenHeight - bubble.radius, newY))
            }
            
            touchBubbles[i] = bubble
        }
    }
    
    // Add bubble repulsion function from original
    private func calculateBubbleRepulsion(for targetBubble: TouchBubble, in allBubbles: [TouchBubble]) -> CGVector {
        var repulsionForce = CGVector.zero
        
        for bubble in allBubbles {
            guard bubble.id != targetBubble.id else { continue }
            
            let dx = targetBubble.position.x - bubble.position.x
            let dy = targetBubble.position.y - bubble.position.y
            let distance = hypot(dx, dy)
            
            // Only apply repulsion if bubbles are close - Match original
            let repulsionRadius: CGFloat = 80 // Match original repulsion radius
            if distance < repulsionRadius && distance > 1 {
                let repulsionStrength: CGFloat = 0.5 // Match original repulsion strength
                let normalizedDx = dx / distance
                let normalizedDy = dy / distance
                
                // Stronger repulsion when closer
                let strength = repulsionStrength * (repulsionRadius - distance) / repulsionRadius
                
                repulsionForce.dx += normalizedDx * strength
                repulsionForce.dy += normalizedDy * strength
            }
        }
        
        return repulsionForce
    }
    
    // MARK: - Physics Calculations
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
        
        // Perpendicular vector for orbital motion
        return CGVector(
            dx: -dy / distance * orbitSpeed,
            dy: dx / distance * orbitSpeed
        )
    }
    
    // MARK: - Original Functions
    func area(for y: CGFloat, totalHeight: CGFloat) -> Int? {
        guard totalHeight > 0 else { return nil }
        let h = totalHeight / 3
        switch y {
        case 0..<h:
            return 0
        case h..<(2*h):
            return 1
        case (2*h)...:
            return 2
        default:
            return nil
        }
    }
    
    func triggerHapticByCircle(for circle: String, area: Int) {
        switch circle {
        case "circle0":
            switch area {
            case 0:
                HapticManager.playAHAP(named: "bubble")
                print("playing haptic circle0 - 0")
            case 1:
                HapticManager.playAHAP(named: "bubble_75")
                print("playing haptic circle0 - 1")
            case 2:
                HapticManager.playAHAP(named: "bubble_50")
                print("playing haptic circle0 - 2")
            default:
                break
            }
            
        case "circle1":
            switch area {
            case 0:
                HapticManager.playAHAP(named: "heavy50")
                print("playing haptic circle1 - 0")
            case 1:
                HapticManager.playAHAP(named: "heavy50_75")
                print("playing haptic circle1 - 1")
            case 2:
                HapticManager.playAHAP(named: "heavy50_50")
                print("playing haptic circle1 - 2")
            default:
                break
            }
            
        case "circle2":
            switch area {
            case 0:
                HapticManager.playAHAP(named: "heavy75")
                print("playing haptic circle2 - 0")
            case 1:
                HapticManager.playAHAP(named: "heavy75_75")
                print("playing haptic circle2 - 1")
            case 2:
                HapticManager.playAHAP(named: "heavy75_50")
                print("playing haptic circle2 - 2")
            default:
                break
            }
            
        default:
            break
        }
    }
    
    func triggerHaptic(for color: Color) {
        switch color {
        case .red:    HapticManager.notification(.success)
        case .yellow: HapticManager.selection()
        case .gray:   HapticManager.notification(.warning)
        case .green:  HapticManager.notification(.error)
        case .brown:  HapticManager.impact(.heavy)
        case .indigo: HapticManager.impact(.soft)
        default: break
        }
    }
}

#Preview {
    ResultScreenView()
        .environmentObject(SelectedHaptic())
}
