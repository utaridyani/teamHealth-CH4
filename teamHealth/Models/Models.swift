//
//  Models.swift
//  teamHealth
//
//  Created by Zap on 21/08/25.
//


import SwiftUI

// MARK: - Sphere Configuration
enum SphereType: Int, CaseIterable {
    case dawn = 0
    case twilight = 1
    case reverie = 2
    
    var name: String {
        switch self {
        case .dawn: return "Dawn"
        case .twilight: return "Twilight"
        case .reverie: return "Reverie"
        }
    }
    
    var hapticID: String {
        return "circle\(self.rawValue)"
    }
    
    var baseColor: Color {
        switch self {
        case .dawn:
            return Color(red: 1.0, green: 0.85, blue: 0.6)
        case .twilight:
            return Color(red: 0.7, green: 0.6, blue: 1.0)
        case .reverie:
            return Color(red: 0.5, green: 0.8, blue: 1.0)
        }
    }
    
    var gradientColors: [Color] {
        switch self {
        case .dawn:
            return [
                Color.white,
                Color(red: 1.0, green: 0.9, blue: 0.7),
                Color(red: 1.0, green: 0.8, blue: 0.5),
                Color(red: 0.95, green: 0.7, blue: 0.4)
            ]
        case .twilight:
            return [
                Color.white,
                Color(red: 0.9, green: 0.8, blue: 1.0),
                Color(red: 0.8, green: 0.7, blue: 1.0),
                Color(red: 0.7, green: 0.5, blue: 0.9)
            ]
        case .reverie:
            return [
                Color.white,
                Color(red: 0.8, green: 0.95, blue: 1.0),
                Color(red: 0.6, green: 0.85, blue: 1.0),
                Color(red: 0.4, green: 0.75, blue: 0.95)
            ]
        }
    }
    
    var backgroundGradient: LinearGradient {
        switch self {
        case .dawn:
            return LinearGradient(
                stops: [
                    Gradient.Stop(color: Color(red: 0.1, green: 0.1, blue: 0.1), location: 0.00),
                    Gradient.Stop(color: Color(red: 1, green: 0.76, blue: 0.32), location: 1.00),
                ],
                startPoint: UnitPoint(x: 0.1, y: -0.02),
                endPoint: UnitPoint(x: 1.18, y: 3.00)
            )
        case .twilight:
            return LinearGradient(
                stops: [
                    Gradient.Stop(color: Color(red: 0.05, green: 0.05, blue: 0.05), location: 0.00),
                    Gradient.Stop(color: Color(red: 0.23, green: 0.07, blue: 0.4).opacity(0.7), location: 0.57),
                    Gradient.Stop(color: Color(red: 1, green: 0.73, blue: 0.9).opacity(0.9), location: 1.00),
                ],
                startPoint: UnitPoint(x: 0.1, y: -0.02),
                endPoint: UnitPoint(x: 1.18, y: 2.00)
            )
        case .reverie:
            return LinearGradient(
                stops: [
                    Gradient.Stop(color: Color(red: 0.1, green: 0.1, blue: 0.1), location: 0.00),
                    Gradient.Stop(color: Color(red: 0, green: 0.5, blue: 0.8).opacity(0.8), location: 1),
                ],
                startPoint: UnitPoint(x: 0.1, y: -0.02),
                endPoint: UnitPoint(x: 1.3, y: 2)
            )
        }
    }
    
    var instructionText: String {
        switch self {
        case .dawn:
            return "Tap to preview the haptics"
        case .twilight:
            return "Tap to preview the haptics"
        case .reverie:
            return "Tap to preview the haptics"
        }
    }
}

// MARK: - Star Model
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
        self.baseSize = CGFloat.random(in: 0.5...0.8)
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

// MARK: - Physics Constants
struct PhysicsConstants {
    static let bubbleCount = 8
    static let pullStrength: CGFloat = 1.2
    static let damping: CGFloat = 0.88
    static let maxSpeed: CGFloat = 12
    static let orbitSpeed: CGFloat = 0.7
    static let repulsionRadius: CGFloat = 80
    static let repulsionStrength: CGFloat = 0.5
    static let chaosStrength: CGFloat = 0.8
}

// MARK: - Animation Constants
struct AnimationConstants {
    static let spherePulseMinScale: CGFloat = 0.95
    static let spherePulseMaxScale: CGFloat = 1.05
    static let sphereGlowIntensity: Double = 0.8
    static let sphereHoldDuration: TimeInterval = 3.0
    static let threeFingerHoldDuration: TimeInterval = 2.0
    static let hapticInterval: TimeInterval = 0.2
}
