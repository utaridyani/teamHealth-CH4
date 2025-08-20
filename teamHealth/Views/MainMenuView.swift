//
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
    @State private var currentSphereType: SphereType = .dawn
    @State private var isPressing = false
    @State private var holdWork: DispatchWorkItem? = nil
    @State private var lastHapticTime: Date = .distantPast
    
    // Sphere animation states
    @State private var sphereScale: CGFloat = 1.0
    @State private var sphereGlowIntensity: Double = AnimationConstants.sphereGlowIntensity
    
    // Expanded mode state
    @State private var isExpanded = false
    
    // Star animation
    @State private var stars: [Star] = []
    private let starCount = 100
    
    // Touch tracking
    @State private var touches: [Int: CGPoint] = [:]
    @State private var lastTimes: [Int: Date] = [:]
    
    // Three finger hold to go back
    @State private var threeIDs: Set<Int> = []
    @State private var threeStartPositions: [Int:CGPoint] = [:]
    @State private var threeHoldWork: DispatchWorkItem?
    @State private var threeFingersHold = false
    let threeMoveTolerance: CGFloat = 30
    
    // Timers
    private let starTimer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()
    private let bubbleTimer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        GeometryReader { geo in
            ZStack {
                // Background gradient - always visible
                currentSphereType.backgroundGradient
                    .ignoresSafeArea()
                
                // Animated stars - always visible
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
                                        glowIntensity: $sphereGlowIntensity
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
                initializeStars()
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
                }
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
                    
                    withAnimation(.easeInOut(duration: 0.2)) {
                        sphereScale = 0.9
                        sphereGlowIntensity = 1.2
                    }
                    
                    // Hold to expand
                    let work = DispatchWorkItem {
                        print("Expanding sphere \(sphereType.name)")
                        
                        // Save selection
                        selectedHaptic.selectedCircle = sphereType.hapticID
                        selectedHaptic.selectedColor = sphereType.baseColor
                        
                        // Success haptic
                        HapticManager.notification(.success)
                        
                        // Expand animation
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                            isExpanded = true
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
                
                // Restore scale if not expanded
                if !isExpanded {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        sphereScale = 1.0
                        sphereGlowIntensity = AnimationConstants.sphereGlowIntensity
                    }
                }
            }
    }
    
    // MARK: - Touch Handling for Expanded Mode
    private func handleTouchChange(_ newTouches: [Int: CGPoint]) {
        touches = newTouches
        bubbleManager.updateTouches(newTouches, sphereType: currentSphereType)
        
        let now = Date()
        let screenHeight = UIScreen.main.bounds.height
        
        // Haptic feedback for touches
        for (id, point) in newTouches {
            if now.timeIntervalSince(lastTimes[id] ?? .distantPast) > AnimationConstants.hapticInterval {
                lastTimes[id] = now
                
                if let a = area(for: point.y, totalHeight: screenHeight) {
                    triggerHapticByCircle(for: currentSphereType.hapticID, area: a)
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
}

#Preview {
    MainMenuView()
        .environmentObject(SelectedHaptic())
}
