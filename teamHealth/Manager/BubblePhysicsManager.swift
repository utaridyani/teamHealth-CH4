//
//  BubblePhysicsManager.swift
//  teamHealth
//
//  Created by Zap on 20/08/25.
//


import SwiftUI

class BubblePhysicsManager: ObservableObject {
    @Published var touchBubbles: [TouchBubble] = []
    private var touches: [Int: CGPoint] = [:]
    
    func updateTouches(_ newTouches: [Int: CGPoint], sphereType: SphereType) {
        touches = newTouches
        updateBubblesForTouches(newTouches, sphereType: sphereType)
    }
    
    func clearAll() {
        touchBubbles.removeAll()
        touches.removeAll()
    }
    
    private func updateBubblesForTouches(_ newTouches: [Int: CGPoint], sphereType: SphereType) {
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
                spawnBubblesForTouch(touchID: touchID, position: touchPosition, sphereType: sphereType)
            }
        }
    }
    
    private func spawnBubblesForTouch(touchID: Int, position: CGPoint, sphereType: SphereType) {
        for _ in 0..<PhysicsConstants.bubbleCount {
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
                color: sphereType.baseColor,
                touchID: touchID
            )
            
            touchBubbles.append(bubble)
        }
    }
    
    func updatePhysics() {
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
                    dx: CGFloat.random(in: -PhysicsConstants.chaosStrength...PhysicsConstants.chaosStrength),
                    dy: CGFloat.random(in: -PhysicsConstants.chaosStrength...PhysicsConstants.chaosStrength)
                )
                let repulsionForce = calculateBubbleRepulsion(for: bubble, in: touchBubbles)
                
                // Apply forces
                bubble.velocity.dx += gravityForce.dx * 0.7 + orbitalForce.dx * 0.2 + chaosForce.dx + repulsionForce.dx * 0.3
                bubble.velocity.dy += gravityForce.dy * 0.7 + orbitalForce.dy * 0.2 + chaosForce.dy + repulsionForce.dy * 0.3
                
                // Damping
                bubble.velocity.dx *= PhysicsConstants.damping
                bubble.velocity.dy *= PhysicsConstants.damping
                
                // Speed limit
                let speed = hypot(bubble.velocity.dx, bubble.velocity.dy)
                if speed > PhysicsConstants.maxSpeed {
                    let scale = PhysicsConstants.maxSpeed / speed
                    bubble.velocity.dx *= scale
                    bubble.velocity.dy *= scale
                }
                
                // Update position with bounds
                let screenBounds = UIScreen.main.bounds
                bubble.position.x = max(bubble.radius, min(screenBounds.width - bubble.radius, bubble.position.x + bubble.velocity.dx))
                bubble.position.y = max(bubble.radius, min(screenBounds.height - bubble.radius, bubble.position.y + bubble.velocity.dy))
            }
            
            touchBubbles[i] = bubble
        }
    }
    
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
        
        return CGVector(
            dx: -dy / distance * PhysicsConstants.orbitSpeed,
            dy: dx / distance * PhysicsConstants.orbitSpeed
        )
    }
    
    private func calculateBubbleRepulsion(for targetBubble: TouchBubble, in allBubbles: [TouchBubble]) -> CGVector {
        var repulsionForce = CGVector.zero
        
        for bubble in allBubbles {
            guard bubble.id != targetBubble.id else { continue }
            
            let dx = targetBubble.position.x - bubble.position.x
            let dy = targetBubble.position.y - bubble.position.y
            let distance = hypot(dx, dy)
            
            if distance < PhysicsConstants.repulsionRadius && distance > 1 {
                let normalizedDx = dx / distance
                let normalizedDy = dy / distance
                let strength = PhysicsConstants.repulsionStrength * (PhysicsConstants.repulsionRadius - distance) / PhysicsConstants.repulsionRadius
                
                repulsionForce.dx += normalizedDx * strength
                repulsionForce.dy += normalizedDy * strength
            }
        }
        
        return repulsionForce
    }
}
