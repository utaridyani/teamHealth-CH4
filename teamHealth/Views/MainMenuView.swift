//
//  MainMenuView.swift
//  test_haptics
//
//  Created by Utari Dyani Laksmi on 14/08/25.
//
//
//
//  MainMenuView.swift
//  test_haptics
//
//  Created by Utari Dyani Laksmi on 14/08/25.
//

import SwiftUI

// MARK: - Star Model for Animation
struct Star: Identifiable {
    let id = UUID()
    var angle: CGFloat // Direction from center
    var distance: CGFloat // Distance from center
    var speed: CGFloat
    var baseSize: CGFloat
    
    init() {
        // Each star starts from the center with a random direction
        self.angle = CGFloat.random(in: 0...(2 * .pi))
        self.distance = 1.0 // Start very close to center
        self.speed = CGFloat.random(in: 50...150) // Speed of movement outward
        self.baseSize = CGFloat.random(in: 0.5...2.0)
    }
    
    // Calculate actual position based on angle and distance
    func position(centerX: CGFloat, centerY: CGFloat) -> CGPoint {
        return CGPoint(
            x: centerX + cos(angle) * distance,
            y: centerY + sin(angle) * distance
        )
    }
    
    // Calculate size based on distance (closer = smaller, farther = bigger)
    var currentSize: CGFloat {
        return baseSize * min(distance / 100, 3.0)
    }
    
    // Calculate opacity based on distance
    var currentOpacity: Double {
        let maxDistance: CGFloat = 400
        let opacity = min(distance / maxDistance, 1.0)
        return Double(max(0.1, opacity))
    }
}

struct MainMenuView: View {
    @EnvironmentObject var hapticData: HapticData // no longer used
    @EnvironmentObject var selectedHaptic: SelectedHaptic
    
    @State private var selection = 0
    
    @State private var lastHapticTime: Date = .distantPast
    @State private var holdWork: DispatchWorkItem? = nil
    @State private var isPressing = false
    let hapticInterval: TimeInterval = 0.2
    
    @State private var moveToResultView = false
    
    // Updated star animation state
    @State private var stars: [Star] = []
    private let starCount = 100 // Reasonable amount for smooth performance
    
    // Timer for smooth animation
    private let timer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    // Animated moving stars - infinite space travel effect
                    ForEach(stars) { star in
                        let starPosition = star.position(centerX: screenWidth/2, centerY: screenHeight/2)
                        
                        Circle()
                            .fill(Color.white.opacity(star.currentOpacity))
                            .frame(width: star.currentSize, height: star.currentSize)
                            .position(starPosition)
                            .blur(radius: star.distance < 50 ? 0.5 : 0) // Slight blur for very close stars
                    }
                    
                    VStack {
                        TabView(selection: $selection) {
                            // HAPTIC 1 (Circle 0)
                            Circle()
                                .fill(.red)
                                .frame(width: geo.size.width/2, height: geo.size.height/3)
                                .tag(0)
                                .contentShape(Circle())
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { _ in
                                            if !isPressing {
                                                isPressing = true
                                                let color = Color.red
                                                // play haptic when tap
                                                triggerHaptic(for: "circle0")
                                                
                                                // hold for 3 secs
                                                let work = DispatchWorkItem {
                                                    print("hold > 3s on circle 0")
                                                    // HapticManager.notification(.success)
                                                    
                                                    // save haptic data after holding for 3 seconds
                                                    selectedHaptic.selectedCircle = "circle0"
                                                    selectedHaptic.selectedColor = color
                                                    print("Saved : haptic \(selectedHaptic.$selectedCircle)")
                                                    
                                                    // move to result view after that
                                                    moveToResultView = true
                                                    
                                                    
                                                }
                                                holdWork = work
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: work)
                                            }
                                            else {
                                                // stop haptic while holding
                                                let now = Date()
                                                if now.timeIntervalSince(lastHapticTime) > hapticInterval {
                                                    lastHapticTime = now
                                                    triggerHaptic(for: "circle0")
                                                }
                                            }
                                        }
                                        .onEnded { _ in
                                            isPressing = false
                                            holdWork?.cancel()
                                            holdWork = nil
                                        }
                                )
                            
                            // HAPTIC 2
                            Circle()
                                .fill(.blue)
                                .frame(width: geo.size.width/2, height: geo.size.height/3)
                                .tag(1)
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { _ in
                                            if !isPressing {
                                                isPressing = true
                                                let color = Color.blue
                                                // play haptic when tap
                                                triggerHaptic(for: "circle1")
                                                
                                                // hold for 3 secs
                                                let work = DispatchWorkItem {
                                                    print("hold > 3s on circle 1")
                                                    // HapticManager.notification(.success)
                                                    
                                                    // save haptic data after holding for 3 seconds
                                                    selectedHaptic.selectedCircle = "circle1"
                                                    selectedHaptic.selectedColor = color
                                                    print("Saved : haptic \(selectedHaptic.$selectedCircle)")
                                                    
                                                    // move to result view after that
                                                    moveToResultView = true
                                                    
                                                    
                                                }
                                                holdWork = work
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: work)
                                            }
                                            else {
                                                // stop haptic while holding
                                                let now = Date()
                                                if now.timeIntervalSince(lastHapticTime) > hapticInterval {
                                                    lastHapticTime = now
                                                    triggerHaptic(for: "circle1")
                                                }
                                            }
                                        }
                                        .onEnded { _ in
                                            //                                        HapticManager.stopAllHaptics()
                                            isPressing = false
                                            holdWork?.cancel()
                                            holdWork = nil
                                        }
                                )
                            
                            // HAPTIC 3
                            Circle()
                                .fill(.green)
                                .frame(width: geo.size.width/2, height: geo.size.height/3)
                                .tag(2)
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { _ in
                                            if !isPressing {
                                                isPressing = true
                                                let color = Color.green
                                                // play haptic when tap
                                                triggerHaptic(for: "circle2")
                                                
                                                // hold for 3 secs
                                                let work = DispatchWorkItem {
                                                    print("hold > 3s on circle 2")
                                                    // HapticManager.notification(.success)
                                                    
                                                    // save haptic data after holding for 3 seconds
                                                    selectedHaptic.selectedCircle = "circle2"
                                                    selectedHaptic.selectedColor = color
                                                    print("Saved : haptic \(selectedHaptic.$selectedCircle)")
                                                    
                                                    // move to result view after that
                                                    moveToResultView = true
                                                    
                                                    
                                                }
                                                holdWork = work
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: work)
                                            }
                                            else {
                                                // stop haptic while holding
                                                let now = Date()
                                                if now.timeIntervalSince(lastHapticTime) > hapticInterval {
                                                    lastHapticTime = now
                                                    triggerHaptic(for: "circle2")
                                                }
                                            }
                                        }
                                        .onEnded { _ in
                                            isPressing = false
                                            holdWork?.cancel()
                                            holdWork = nil
                                        }
                                )
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                        .position(x: screenWidth/2, y: screenHeight/2)
                        
                    }
                }
                .onAppear {
                    // Generate initial stars with staggered distances for continuous flow
                    if stars.isEmpty {
                        stars = (0..<starCount).map { index in
                            var star = Star()
                            // Stagger initial distances so stars appear continuously
                            star.distance = CGFloat(index) * 5.0 + CGFloat.random(in: 1...20)
                            return star
                        }
                    }
                }
                .onReceive(timer) { _ in
                    // Animate stars moving outward from center
                    for i in stars.indices {
                        // Move star outward along its angle
                        stars[i].distance += stars[i].speed / 60.0 // 60 FPS
                        
                        // Reset star when it moves too far off screen
                        let maxDistance = sqrt(pow(screenWidth, 2) + pow(screenHeight, 2)) + 100
                        if stars[i].distance > maxDistance {
                            // Create new star at center with random direction
                            stars[i] = Star()
                        }
                    }
                }
                .background {
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
                    } else if selection == 2 {
                        LinearGradient(
                            stops: [
                                Gradient.Stop(color: Color(red: 0.1, green: 0.1, blue: 0.1), location: 0.00),
                                Gradient.Stop(color: Color(red: 0, green: 0.5, blue: 0.8).opacity(0.8), location: 1),
                                //                            Gradient.Stop(color: Color(red: 0, green: 0.5, blue: 0.8).opacity(0.4), location: 1),
                            ],
                            startPoint: UnitPoint(x: 0.1, y: -0.02),
                            endPoint: UnitPoint(x: 1.3, y: 2)
                        )
                    }
                    else {
                        Color.black
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .navigationBarBackButtonHidden()
                .navigationDestination(isPresented: $moveToResultView) {
                    ResultScreenView()
                        .environmentObject(selectedHaptic)
                }
            }
        }
    }
    
    
    // haptics
    func triggerHaptic(for circle: String) {
        switch circle {
        case "circle0":
            HapticManager.playAHAP(named: "bubble")
            print("playing haptic circle0")
        case "circle1":
            HapticManager.playAHAP(named: "heavy50")
            print("playing haptic circle1")
        case "circle2":
            HapticManager.playAHAP(named: "heavy75")
            print("playing haptic circle2")
        default:
            break
        }
    }
}

#Preview {
    MainMenuView()
        .environmentObject(SelectedHaptic())
}
