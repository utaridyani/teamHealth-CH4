//
//  BigBangEffect.swift
//  teamHealth
//
//  Created by Zap on 23/08/25.
//


import SwiftUI

// MARK: - Big Bang Effect Manager
class BigBangEffectManager: ObservableObject {
    @Published var isExploding = false
    @Published var explosionPhase: CGFloat = 0
    @Published var shockwaveRadius: CGFloat = 0
    @Published var shockwaveOpacity: Double = 0
    @Published var flashOpacity: Double = 0
    @Published var coreGlowScale: CGFloat = 1.0
    
    // Multiple shockwave rings
    @Published var shockwaveRings: [ShockwaveRing] = []
    
    // Particle trails for stars
    @Published var starTrails: [StarTrail] = []
    
    func triggerBigBang(stars: inout [Star]) {
        isExploding = true
        explosionPhase = 0
        
        // Flash effect
        withAnimation(.easeOut(duration: 0.1)) {
            flashOpacity = 1.0
        }
        
        withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
            flashOpacity = 0
        }
        
        // Core glow expansion
        withAnimation(.easeOut(duration: 0.3)) {
            coreGlowScale = 3.0
        }
        
        withAnimation(.easeIn(duration: 0.5).delay(0.3)) {
            coreGlowScale = 0.1
        }
        
        // Create multiple shockwave rings
        createShockwaveRings()
        
        // Accelerate all stars outward
        accelerateStars(&stars)
        
        // Create star trails
        createStarTrails(from: stars)
        
        // Play the shockwave haptic
        HapticManager.playAHAP(named: "shockwave")
        
        // Reset after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.isExploding = false
            self.shockwaveRings.removeAll()
            self.starTrails.removeAll()
        }
    }
    
    private func createShockwaveRings() {
        shockwaveRings = []
        
        // Create 3 expanding rings with different speeds
        for i in 0..<3 {
            let delay = Double(i) * 0.15
            let ring = ShockwaveRing(
                id: UUID(),
                initialRadius: 50,
                maxRadius: UIScreen.main.bounds.width * 1.5,
                duration: 2.0 + Double(i) * 0.3,
                delay: delay,
                opacity: 0.8 - Double(i) * 0.2,
                strokeWidth: 3.0 - CGFloat(i) * 0.5
            )
            shockwaveRings.append(ring)
            
            // Animate each ring
            withAnimation(.easeOut(duration: ring.duration).delay(delay)) {
                if let index = shockwaveRings.firstIndex(where: { $0.id == ring.id }) {
                    shockwaveRings[index].currentRadius = ring.maxRadius
                    shockwaveRings[index].currentOpacity = 0
                }
            }
        }
    }
    
    private func accelerateStars(_ stars: inout [Star]) {
        let centerX = UIScreen.main.bounds.width / 2
        let centerY = UIScreen.main.bounds.height / 2
        
        for i in stars.indices {
            let position = stars[i].position(centerX: centerX, centerY: centerY)
            
            // Calculate angle from center to star
            let dx = position.x - centerX
            let dy = position.y - centerY
            let angle = atan2(dy, dx)
            
            // Calculate explosion force based on distance (closer = stronger)
            let distance = max(1, stars[i].distance)
            let explosionForce = 5000.0 / distance
            
            // Apply radial acceleration
            stars[i].explosionVelocity = CGVector(
                dx: cos(angle) * explosionForce,
                dy: sin(angle) * explosionForce
            )
            
            // Increase speed dramatically
            stars[i].speed *= 3.0
            
            // Add some randomness for organic feel
            stars[i].speed += CGFloat.random(in: 50...200)
        }
    }
    
    private func createStarTrails(from stars: [Star]) {
        let centerX = UIScreen.main.bounds.width / 2
        let centerY = UIScreen.main.bounds.height / 2
        
        starTrails = stars.prefix(30).map { star in
            let position = star.position(centerX: centerX, centerY: centerY)
            return StarTrail(
                startPosition: CGPoint(x: centerX, y: centerY),
                endPosition: position,
                opacity: Double.random(in: 0.3...0.7),
                width: CGFloat.random(in: 1...3)
            )
        }
        
        // Fade out trails
        withAnimation(.easeOut(duration: 1.5)) {
            for i in starTrails.indices {
                starTrails[i].opacity = 0
            }
        }
    }
    
    func updateExplosion() {
        guard isExploding else { return }
        
        explosionPhase += 0.016
        
        // Update shockwave rings
        for i in shockwaveRings.indices {
            if shockwaveRings[i].age < shockwaveRings[i].duration {
                shockwaveRings[i].age += 0.016
            }
        }
    }
}

// MARK: - Shockwave Ring Model
struct ShockwaveRing: Identifiable {
    let id: UUID
    let initialRadius: CGFloat
    let maxRadius: CGFloat
    let duration: Double
    let delay: Double
    var opacity: Double
    let strokeWidth: CGFloat
    var currentRadius: CGFloat = 50
    var currentOpacity: Double = 0.8
    var age: Double = 0
}

// MARK: - Star Trail Model
struct StarTrail: Identifiable {
    let id = UUID()
    let startPosition: CGPoint
    let endPosition: CGPoint
    var opacity: Double
    let width: CGFloat
}

// MARK: - Enhanced Star Model Extension
extension Star {
    // Add explosion velocity to Star model
    static var explosionVelocityKey: UInt8 = 0
    
    var explosionVelocity: CGVector {
        get {
            objc_getAssociatedObject(self, &Star.explosionVelocityKey) as? CGVector ?? CGVector.zero
        }
        set {
            objc_setAssociatedObject(self, &Star.explosionVelocityKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    mutating func updateWithExplosion() {
        // Apply explosion velocity
        if explosionVelocity.dx != 0 || explosionVelocity.dy != 0 {
            // Move star based on explosion
            distance += hypot(explosionVelocity.dx, explosionVelocity.dy) * 0.016
            
            // Dampen explosion over time
            explosionVelocity.dx *= 0.98
            explosionVelocity.dy *= 0.98
        }
    }
}

// MARK: - Big Bang Visual Effect View
struct BigBangVisualEffect: View {
    @ObservedObject var effectManager: BigBangEffectManager
    let centerX: CGFloat
    let centerY: CGFloat
    
    var body: some View {
        ZStack {
            // White flash
            if effectManager.flashOpacity > 0 {
                Color.white
                    .opacity(effectManager.flashOpacity)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
            
            // Core glow that expands then contracts
            if effectManager.isExploding {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white,
                                Color.white.opacity(0.8),
                                Color.yellow.opacity(0.6),
                                Color.orange.opacity(0.4),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .scaleEffect(effectManager.coreGlowScale)
                    .blur(radius: 10)
                    .position(x: centerX, y: centerY)
                    .allowsHitTesting(false)
            }
            
            // Shockwave rings
            ForEach(effectManager.shockwaveRings) { ring in
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(ring.currentOpacity),
                                Color.blue.opacity(ring.currentOpacity * 0.7),
                                Color.purple.opacity(ring.currentOpacity * 0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: ring.strokeWidth
                    )
                    .frame(width: ring.currentRadius * 2, height: ring.currentRadius * 2)
                    .position(x: centerX, y: centerY)
                    .blur(radius: ring.age > ring.duration * 0.7 ? 5 : 0)
                    .allowsHitTesting(false)
            }
            
            // Star trails
            ForEach(effectManager.starTrails) { trail in
                Path { path in
                    path.move(to: trail.startPosition)
                    path.addLine(to: trail.endPosition)
                }
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(trail.opacity),
                            Color.white.opacity(trail.opacity * 0.3),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: trail.width
                )
                .blur(radius: 1)
                .allowsHitTesting(false)
            }
        }
    }
}

// MARK: - Particle Burst for Enhanced Effect
struct BigBangParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGVector
    var size: CGFloat
    var color: Color
    var opacity: Double
    var rotation: Double
    var rotationSpeed: Double
    
    mutating func update() {
        position.x += velocity.dx * 0.016
        position.y += velocity.dy * 0.016
        velocity.dx *= 0.99
        velocity.dy *= 0.99
        opacity *= 0.98
        rotation += rotationSpeed * 0.016
    }
}

// MARK: - Enhanced Burst Manager
class EnhancedBurstManager: ObservableObject {
    @Published var particles: [BigBangParticle] = []
    
    func createBigBangParticles(at center: CGPoint, count: Int = 100) {
        particles = (0..<count).map { _ in
            let angle = Double.random(in: 0..<2 * .pi)
            let speed = CGFloat.random(in: 200...500)
            let velocity = CGVector(
                dx: cos(angle) * speed,
                dy: sin(angle) * speed
            )
            
            return BigBangParticle(
                position: center,
                velocity: velocity,
                size: CGFloat.random(in: 2...8),
                color: [Color.white, Color.yellow, Color.orange, Color.red, Color.purple].randomElement()!,
                opacity: Double.random(in: 0.7...1.0),
                rotation: Double.random(in: 0..<2 * .pi),
                rotationSpeed: Double.random(in: -10...10)
            )
        }
    }
    
    func updateParticles() {
        for i in particles.indices {
            particles[i].update()
        }
        particles.removeAll { $0.opacity < 0.01 }
    }
}
