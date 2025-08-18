//
//  HapticsAnimationView.swift
//  teamHealth
//
//  Created by Zap on 18/08/25.
//




import SwiftUI
import CoreGraphics
import Foundation

// MARK: - Models
struct Bubble: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGVector
    var baseSize: CGFloat = 60 // Base size for breathing animation
    var breathingPhase: CGFloat = 0 // Phase for breathing animation
    var breathingSpeed: CGFloat = 1.0 // Individual breathing rate
    var opacity: Double = 0.6
    
    // Computed property for current size with breathing
    var currentSize: CGFloat {
        let breathingMultiplier: CGFloat = 0.3 // How much the size changes (30%)
        let breathing = Foundation.sin(breathingPhase) * breathingMultiplier + 1.0
        return baseSize * breathing
    }
    
    // Convenience computed property for bounds checking
    var radius: CGFloat { currentSize / 2 }
}


// MARK: - Physics Constants
struct PhysicsConstants {
    static let pullStrength: CGFloat = 1.2 // Stronger pull to bring them back
    static let damping: CGFloat = 0.88 // Less damping for more lively movement
    static let maxActiveSpeed: CGFloat = 12 // Higher max speed during active phase
    static let maxIdleSpeed: CGFloat = 2
    static let orbitSpeed: CGFloat = 0.7 // Faster orbiting
    static let jitterRange: ClosedRange<CGFloat> = -0.1...0.1 // More jitter for liveliness
    static let spawnRadiusRange: ClosedRange<CGFloat> = 50...100
    static let frameRate: TimeInterval = 1.0 / 60.0
}

// MARK: - Main View
struct HapticAnimation: View {
    @State private var bubbles: [Bubble] = []
    @State private var gravityCenter: CGPoint?
    @State private var screenBounds: CGRect = UIScreen.main.bounds
    @State private var isTouchActive: Bool = false
    
    private let bubbleCount = 8 // More bubbles for better burst effect
    private let timer = Timer.publish(every: PhysicsConstants.frameRate, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundView
                gravityCenterIndicator
                bubblesView
            }
            .gesture(createDragGesture())
            .onReceive(timer) { _ in
                updateBubbles(in: geometry.size)
            }
            .onAppear {
                screenBounds = CGRect(origin: .zero, size: geometry.size)
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - View Components
    private var backgroundView: some View {
        Color.black
            .ignoresSafeArea()
    }
    
    private var gravityCenterIndicator: some View {
        Group {
            if let center = gravityCenter {
                ZStack {
                    // Outer glow for thumb indicator
                    Circle()
                        .stroke(.blue.opacity(0.3), lineWidth: 6)
                        .frame(width: 90, height: 90)
                        .blur(radius: 4)
                    
                    // Main thumb circle
                    Circle()
                        .stroke(.blue, lineWidth: 3)
                        .frame(width: 80, height: 80)
                        .shadow(color: .blue.opacity(0.5), radius: 3)
                }
                .position(center)
                .animation(.easeInOut(duration: 0.1), value: center)
            }
        }
    }
    
    private var bubblesView: some View {
        ForEach(bubbles) { bubble in
            Circle()
                .fill(.blue.opacity(bubble.opacity))
                .frame(width: bubble.currentSize, height: bubble.currentSize)
                .position(bubble.position)
                .blur(radius: 6)
                .shadow(color: .blue.opacity(0.6), radius: 8)
                .animation(.easeOut(duration: 0.1), value: bubble.position)
        }
    }
    
    // MARK: - Gesture Handling
    private func createDragGesture() -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                handleDragChanged(at: value.location)
            }
            .onEnded { _ in
                handleDragEnded()
            }
    }
    
    private func handleDragChanged(at location: CGPoint) {
        if gravityCenter == nil {
            isTouchActive = true
            gravityCenter = location
            spawnBubbles(around: location)
        } else {
            gravityCenter = location
        }
    }
    
    private func handleDragEnded() {
        isTouchActive = false
        gravityCenter = nil
        
        // Only fade out bubbles after touch ends
        withAnimation(.easeOut(duration: 0.5)) {
            for i in bubbles.indices {
                bubbles[i].opacity = 0
            }
        }
        
        // Remove bubbles after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if !isTouchActive { // Only remove if still not touching
                bubbles.removeAll()
            }
        }
    }
    
    // MARK: - Bubble Management
    private func spawnBubbles(around point: CGPoint) {
        bubbles = (0..<bubbleCount).compactMap { _ in
            createRandomBubble(around: point)
        }
        // Ensure all bubbles start with full opacity
        for i in bubbles.indices {
            bubbles[i].opacity = Double.random(in: 0.4...0.8)
        }
    }
    
    private func createRandomBubble(around point: CGPoint) -> Bubble {
        // Start all bubbles at the center point
        let position = point
        
        // Give them strong initial burst velocity
        let angle = Double.random(in: 0..<2 * .pi)
        let burstSpeed = CGFloat.random(in: 8...15) // Much stronger initial burst
        let initialVelocity = CGVector(
            dx: cos(angle) * burstSpeed,
            dy: sin(angle) * burstSpeed
        )
        
        return Bubble(
            position: position,
            velocity: initialVelocity,
            baseSize: CGFloat.random(in: 50...70), // Base size for breathing
            breathingPhase: CGFloat.random(in: 0...2 * .pi), // Random starting phase
            breathingSpeed: CGFloat.random(in: 0.8...1.5), // Varied breathing rates
            opacity: Double.random(in: 0.6...0.9)
        )
    }
    
    // MARK: - Physics Updates
    private func updateBubbles(in screenSize: CGSize) {
        guard !bubbles.isEmpty else { return }
        
        if let center = gravityCenter {
            updateBubblesWithGravity(center: center, screenSize: screenSize)
        } else {
            updateBubblesInIdleMode(screenSize: screenSize)
        }
    }
    
    private func updateBubblesWithGravity(center: CGPoint, screenSize: CGSize) {
        bubbles = bubbles.map { bubble in
            var updatedBubble = bubble
            
            // Update breathing animation
            updatedBubble.breathingPhase += 0.1 * updatedBubble.breathingSpeed
            
            // Calculate attraction force toward center
            let gravityForce = calculateGravityForce(from: bubble.position, to: center)
            
            // Add orbital motion around the gravity center
            let orbitalForce = calculateOrbitalForce(from: bubble.position, around: center)
            
            // Add chaotic movement for organic feel
            let chaosStrength: CGFloat = 0.8
            let chaosForce = CGVector(
                dx: CGFloat.random(in: -chaosStrength...chaosStrength),
                dy: CGFloat.random(in: -chaosStrength...chaosStrength)
            )
            
            // Add some repulsion between bubbles for spreading
            let repulsionForce = calculateBubbleRepulsion(for: bubble, in: bubbles)
            
            // Combine all forces with different weights
            updatedBubble.velocity.dx += gravityForce.dx * 0.7 + orbitalForce.dx * 0.2 + chaosForce.dx + repulsionForce.dx * 0.3
            updatedBubble.velocity.dy += gravityForce.dy * 0.7 + orbitalForce.dy * 0.2 + chaosForce.dy + repulsionForce.dy * 0.3
            
            updatedBubble.velocity = applyDamping(to: updatedBubble.velocity)
            updatedBubble.velocity = limitVelocity(updatedBubble.velocity, maxSpeed: PhysicsConstants.maxActiveSpeed)
            
            // Update position with bounds checking
            updatedBubble.position = updatePosition(
                from: updatedBubble.position,
                velocity: updatedBubble.velocity,
                bubble: updatedBubble,
                screenSize: screenSize
            )
            
            return updatedBubble
        }
    }
    
    private func updateBubblesInIdleMode(screenSize: CGSize) {
        let idleCenter = CGPoint(x: screenSize.width / 2, y: screenSize.height / 2)
        
        bubbles = bubbles.map { bubble in
            var updatedBubble = bubble
            
            // Update breathing animation
            updatedBubble.breathingPhase += 0.08 * updatedBubble.breathingSpeed // Slower in idle mode
            
            // Calculate orbital motion
            let orbitalForce = calculateOrbitalForce(from: bubble.position, around: idleCenter)
            let jitter = CGVector(
                dx: CGFloat.random(in: PhysicsConstants.jitterRange),
                dy: CGFloat.random(in: PhysicsConstants.jitterRange)
            )
            
            // Apply forces
            updatedBubble.velocity.dx += orbitalForce.dx + jitter.dx
            updatedBubble.velocity.dy += orbitalForce.dy + jitter.dy
            updatedBubble.velocity = limitVelocity(updatedBubble.velocity, maxSpeed: PhysicsConstants.maxIdleSpeed)
            
            // Update position
            updatedBubble.position = updatePosition(
                from: updatedBubble.position,
                velocity: updatedBubble.velocity,
                bubble: updatedBubble,
                screenSize: screenSize
            )
            
            return updatedBubble
        }
    }
    
    private func calculateBubbleRepulsion(for targetBubble: Bubble, in allBubbles: [Bubble]) -> CGVector {
        var repulsionForce = CGVector.zero
        
        for bubble in allBubbles {
            guard bubble.id != targetBubble.id else { continue }
            
            let dx = targetBubble.position.x - bubble.position.x
            let dy = targetBubble.position.y - bubble.position.y
            let distance = hypot(dx, dy)
            
            // Only apply repulsion if bubbles are close
            let repulsionRadius: CGFloat = 80 // Increased for bigger bubbles
            if distance < repulsionRadius && distance > 1 {
                let repulsionStrength: CGFloat = 0.5
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
            dx: (dx / distance) * PhysicsConstants.pullStrength,
            dy: (dy / distance) * PhysicsConstants.pullStrength
        )
    }
    
    private func calculateOrbitalForce(from position: CGPoint, around center: CGPoint) -> CGVector {
        let dx = position.x - center.x
        let dy = position.y - center.y
        let distance = max(1, hypot(dx, dy))
        
        // Perpendicular vector for orbital motion
        return CGVector(
            dx: -dy / distance * PhysicsConstants.orbitSpeed,
            dy: dx / distance * PhysicsConstants.orbitSpeed
        )
    }
    
    private func applyDamping(to velocity: CGVector) -> CGVector {
        return CGVector(
            dx: velocity.dx * PhysicsConstants.damping,
            dy: velocity.dy * PhysicsConstants.damping
        )
    }
    
    private func limitVelocity(_ velocity: CGVector, maxSpeed: CGFloat) -> CGVector {
        let speed = hypot(velocity.dx, velocity.dy)
        guard speed > maxSpeed else { return velocity }
        
        let scale = maxSpeed / speed
        return CGVector(
            dx: velocity.dx * scale,
            dy: velocity.dy * scale
        )
    }
    
    private func updatePosition(from position: CGPoint, velocity: CGVector, bubble: Bubble, screenSize: CGSize) -> CGPoint {
        var newPosition = CGPoint(
            x: position.x + velocity.dx,
            y: position.y + velocity.dy
        )
        
        // Bounds checking with bubble radius
        let radius = bubble.radius
        newPosition.x = max(radius, min(screenSize.width - radius, newPosition.x))
        newPosition.y = max(radius, min(screenSize.height - radius, newPosition.y))
        
        return newPosition
    }
}

// MARK: - Preview
#Preview {
    HapticAnimation()
}
