//
//  BigBangEffect.swift
//  teamHealth
//
//  Created by Zap on 23/08/25.
//

import SwiftUI

// MARK: - Optimized Big Bang Effect Manager
class BigBangEffectManager: ObservableObject {
    @Published var isExploding = false
    @Published var flashOpacity: Double = 0
    @Published var coreScale: CGFloat = 1.0
    @Published var shockwaveData: ShockwaveData = ShockwaveData()
    
    // Single timer for all animations
    private var displayLink: CADisplayLink?
    private var startTime: TimeInterval = 0
    private var explosionDuration: TimeInterval = 3.0
    
    func triggerBigBang(stars: inout [Star]) {
        guard !isExploding else { return }
        
        isExploding = true
        startTime = CACurrentMediaTime()
        
        // Single flash animation
        flashOpacity = 1.0
        
        // Accelerate stars (simplified)
        accelerateStars(&stars)
        
        // Play haptic
        HapticManager.playAHAP(named: "shockwave")
        
        // Start display link for smooth animation
        startDisplayLink()
        
        // Clean up after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + explosionDuration) {
            self.cleanup()
        }
    }
    
    private func startDisplayLink() {
        displayLink?.invalidate()
        displayLink = CADisplayLink(target: self, selector: #selector(updateAnimation))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc private func updateAnimation() {
        let elapsed = CACurrentMediaTime() - startTime
        let progress = min(elapsed / explosionDuration, 1.0)
        
        // Update all animations based on single progress value
        updateFlash(progress: progress)
        updateCore(progress: progress)
        updateShockwave(progress: progress)
        
        if progress >= 1.0 {
            displayLink?.invalidate()
            displayLink = nil
        }
    }
    
    private func updateFlash(progress: Double) {
        // Quick flash that fades out
        if progress < 0.1 {
            flashOpacity = 1.0 - (progress * 10)
        } else {
            flashOpacity = 0
        }
    }
    
    private func updateCore(progress: Double) {
        // Core expansion and contraction
        if progress < 0.2 {
            coreScale = 1.0 + (progress * 10) // Expands to 3x
        } else if progress < 0.4 {
            let contractProgress = (progress - 0.2) * 5
            coreScale = 3.0 - (contractProgress * 2.9) // Contracts to 0.1
        } else {
            coreScale = 0.1
        }
    }
    
    private func updateShockwave(progress: Double) {
        // Single optimized shockwave
        shockwaveData.radius = progress * UIScreen.main.bounds.width * 1.2
        shockwaveData.opacity = max(0, 1.0 - progress)
        shockwaveData.strokeWidth = max(0.5, 3.0 * (1.0 - progress))
    }
    
    private func accelerateStars(_ stars: inout [Star]) {
        let centerX = UIScreen.main.bounds.width / 2
        let centerY = UIScreen.main.bounds.height / 2
        
        // Optimize by only affecting visible stars
        for i in stars.indices where stars[i].distance < 500 {
            let position = stars[i].position(centerX: centerX, centerY: centerY)
            
            let dx = position.x - centerX
            let dy = position.y - centerY
            let angle = atan2(dy, dx)
            
            // Simplified explosion force
            let explosionForce = 3000.0 / max(1, stars[i].distance)
            
            // Store velocity directly in the star
            stars[i].explosionVelocityX = cos(angle) * explosionForce
            stars[i].explosionVelocityY = sin(angle) * explosionForce
            stars[i].speed *= 2.5
        }
    }
    
    private func cleanup() {
        isExploding = false
        flashOpacity = 0
        coreScale = 1.0
        shockwaveData = ShockwaveData()
        displayLink?.invalidate()
        displayLink = nil
    }
}

// MARK: - Simplified Data Structures
struct ShockwaveData {
    var radius: CGFloat = 0
    var opacity: Double = 0
    var strokeWidth: CGFloat = 3
}

// MARK: - Star Explosion Storage
// Global storage for star explosion velocities (more efficient than associated objects)
private var starExplosionVelocities: [UUID: CGVector] = [:]

// MARK: - Enhanced Star Model Extension (Optimized)
extension Star {
    var explosionVelocity: CGVector {
        get { starExplosionVelocities[id] ?? .zero }
        set {
            if newValue == .zero {
                starExplosionVelocities.removeValue(forKey: id)
            } else {
                starExplosionVelocities[id] = newValue
            }
        }
    }
    
    var explosionVelocityX: CGFloat {
        get { explosionVelocity.dx }
        set {
            var velocity = explosionVelocity
            velocity.dx = newValue
            explosionVelocity = velocity
        }
    }
    
    var explosionVelocityY: CGFloat {
        get { explosionVelocity.dy }
        set {
            var velocity = explosionVelocity
            velocity.dy = newValue
            explosionVelocity = velocity
        }
    }
    
    mutating func updateWithExplosion() {
        let velocity = explosionVelocity
        if velocity.dx != 0 || velocity.dy != 0 {
            // Apply explosion velocity
            distance += hypot(velocity.dx, velocity.dy) * 0.016
            
            // Dampen explosion over time
            explosionVelocity = CGVector(
                dx: velocity.dx * 0.98,
                dy: velocity.dy * 0.98
            )
            
            // Clean up when velocity is negligible
            if abs(velocity.dx) < 0.1 && abs(velocity.dy) < 0.1 {
                explosionVelocity = .zero
            }
        }
    }
    
    static func cleanupExplosionData() {
        starExplosionVelocities.removeAll()
    }
}

// MARK: - Optimized Visual Effect View
struct BigBangVisualEffect: View {
    @ObservedObject var effectManager: BigBangEffectManager
    let centerX: CGFloat
    let centerY: CGFloat
    
    var body: some View {
        ZStack {
            // White flash (single layer)
            if effectManager.flashOpacity > 0 {
                Color.white
                    .opacity(effectManager.flashOpacity)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
            
            // Core glow (simplified)
            if effectManager.isExploding && effectManager.coreScale > 0.1 {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                .white,
                                .yellow.opacity(0.6),
                                .clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)
                    .scaleEffect(effectManager.coreScale)
                    .blur(radius: 8)
                    .position(x: centerX, y: centerY)
                    .allowsHitTesting(false)
            }
            
            // Single shockwave ring (instead of multiple)
            if effectManager.shockwaveData.opacity > 0 {
                Circle()
                    .stroke(
                        Color.white.opacity(effectManager.shockwaveData.opacity),
                        lineWidth: effectManager.shockwaveData.strokeWidth
                    )
                    .frame(
                        width: effectManager.shockwaveData.radius * 2,
                        height: effectManager.shockwaveData.radius * 2
                    )
                    .position(x: centerX, y: centerY)
                    .allowsHitTesting(false)
            }
        }
    }
}

// MARK: - Lightweight Particle System (Optional)
struct LightweightParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGVector
    var life: Double = 1.0
    
    mutating func update() {
        position.x += velocity.dx * 0.016
        position.y += velocity.dy * 0.016
        velocity.dx *= 0.98
        velocity.dy *= 0.98
        life -= 0.02
    }
}

class ParticleManager: ObservableObject {
    @Published var particles: [LightweightParticle] = []
    private let maxParticles = 30 // Limit particle count
    
    func createBurst(at center: CGPoint) {
        particles = (0..<maxParticles).map { _ in
            let angle = Double.random(in: 0..<2 * .pi)
            let speed = CGFloat.random(in: 150...300)
            return LightweightParticle(
                position: center,
                velocity: CGVector(
                    dx: cos(angle) * speed,
                    dy: sin(angle) * speed
                )
            )
        }
    }
    
    func update() {
        for i in particles.indices {
            particles[i].update()
        }
        particles.removeAll { $0.life <= 0 }
    }
}
