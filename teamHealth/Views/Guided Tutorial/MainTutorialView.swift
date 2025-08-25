//
//  DividedView.swift
//  test_haptics
//
//  Created by Utari Dyani Laksmi on 22/08/25.
//

import SwiftUI

struct MainTutorialView: View {
    let onComplete: () -> Void
    
    // MARK: Phases
    enum Phase { case carousel, guide, blank, tapguide, intensity, lasttext, swiperight }
    
    struct Theme: Identifiable { let id = UUID(); let name: String; let color: Color }
    private let themes: [Theme] = [
        .init(name: "Dawn",     color: Color(hue: 0.72, saturation: 0.22, brightness: 0.98)),
        .init(name: "Reverie",  color: Color(hue: 0.85, saturation: 0.28, brightness: 0.97)),
        .init(name: "Twilight", color: Color(hue: 0.55, saturation: 0.30, brightness: 0.96))
        
    ]
    
    @State private var index = 0
    @State private var advance = false
     
    // phase
    @State private var phase: Phase = .tapguide
    
    @State private var centerScale: CGFloat = 1.0
    @State private var sideFade: Double = 1.0
    
    // guide state
    @State private var guideStep = 0
    @State private var didLongPress = false
    
    // Star animation - can inherit from onboarding
    @State private var stars: [Star]
    private let starCount = 400
    
    // Sound
    @State private var isMuted = false
    
    // Initializer to support inherited stars or create new ones
    init(inheritedStars: [Star] = [], onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
        
        if inheritedStars.isEmpty {
            self._stars = State(initialValue: (0..<starCount).map { index in
                var star = Star()
                star.distance = CGFloat(index) * 5.0 + CGFloat.random(in: 1...10)
                return star
            })
        } else {
            // Use inherited stars from onboarding
            self._stars = State(initialValue: inheritedStars)
        }
    }
    
    // Timers
    private let starTimer = Timer.publish(every: 1.0 / 60.0, on: .main, in: .common).autoconnect()
    
    private let red = Color(red: 0.96, green: 0.24, blue: 0.20)
    
    var body: some View {
//        let screenWidth = UIScreen.main.bounds.width
//        let screenHeight = UIScreen.main.bounds.height
        
        ZStack {
            Color.black.ignoresSafeArea()
            
            switch phase {
            case .carousel:
                CarouselPhaseView(
                    stars: $stars,
                    themes: themes,
                    red: red,
                    index: $index,
                    advance: $advance,
                    onFinishedSlides: startZoomingPhase
                )
                .transition(.opacity)
                
            case .guide:
                GuidePhaseView(
                    stars: $stars,
                    sphereType: .twilight,
                    step: $guideStep,
                    didLongPress: $didLongPress,
                    onFinishedSlides: startBlankPhase
                )
                .transition(.opacity)
                
            case .blank:
                BlankPhaseView(
                    stars: $stars,
                    onFinishedSlides: startTapGuidePhase
                )
                .transition(.opacity)
                
            case .tapguide:
                TapGuidePhaseView(
                    stars: $stars,
                    onFinishedSlides: intensityGuidePhase
                )
                    .transition(.opacity)
                
            case .intensity:
                IntensityPhaseView(
                    stars: $stars,
                    onFinishedSlides: lastTextPhase
                )
                    .transition(.opacity)
                
            case .lasttext:
                LastTextPhaseView(
                    stars: $stars,
                    onFinishedSlides: swipeRightPhase
                )
                    .transition(.opacity)
                
            case .swiperight:
                SwipeRightPhaseView(
                    stars: $stars,
                    onComplete: onComplete
                )
                    .transition(.opacity)
            }
        }
        .onAppear {
            if stars.isEmpty {
                initializeStars()
            }
        }
        .onReceive(starTimer) { _ in
            updateStars()
        }
    }
    
    // MARK: Phase Transitions
    private func startZoomingPhase() {
        phase = .guide
    }
    
    private func startBlankPhase() {
        phase = .blank
    }
    
    private func startTapGuidePhase() {
        phase = .tapguide
    }
    
    private func intensityGuidePhase() {
        phase = .intensity
    }
    private func lastTextPhase() {
        phase = .lasttext
    }
    private func swipeRightPhase() {
        phase = .swiperight
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
            stars[i].distance += stars[i].speed / 300.0
            
            if stars[i].distance > maxDistance {
                stars[i] = Star()
            }
        }
    }
}

//MARK: Ambient Background
struct AmbientDecor: View {
    @Binding var stars: [Star]
    @EnvironmentObject var mute: MuteStore

    var body: some View {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        GeometryReader { geo in
            ZStack {
                // background
                Color(red: 25/255, green: 25/255, blue: 25/255)
                
                // sound button
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        mute.isMuted.toggle()
                    }
                    HapticManager.selection()
                } label: {
                    ZStack {
                        // base circle
                        Circle()
                            .fill(Color(red: 25/255, green: 25/255, blue: 25/255))
                            .scaleEffect(mute.isMuted ? 1.0 : 1.1)
                            .animation(.easeInOut(duration: 0.3), value: mute.isMuted)
                        
                        // thin outline
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                            .scaleEffect(mute.isMuted ? 1.0 : 1.1)
                            .animation(.easeInOut(duration: 0.3), value: mute.isMuted)
                        
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    gradient: Gradient(stops: [
                                        .init(color: Color.white.opacity(0.2), location: 0.0),
                                        .init(color: Color.white.opacity(0.05), location: 0.5),
                                        .init(color: Color.clear, location: 1.0)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 8
                            )
                            .blur(radius: 10)
                        
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    gradient: Gradient(stops: [
                                        .init(color: Color.clear, location: 0.0),
                                        .init(color: Color.white.opacity(0.1), location: 0.4),
                                        .init(color: Color.white.opacity(0.9), location: 1.0)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 8
                            )
                            .blur(radius: 10)
                            .animation(.easeInOut(duration: 0.3), value: mute.isMuted)
                        
                        // icon
                        Image(systemName: mute.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                            // smooth morph  when user click
                            .contentTransition(.symbolEffect(.replace))
                            .animation(.easeInOut(duration: 0.3), value: mute.isMuted)
                    }
                    .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .position(x:screenWidth*0.86, y:screenHeight/9)
                
                // stars
                ForEach(stars) { star in
                    let p = star.position(
                        centerX: geo.size.width / 2,
                        centerY: geo.size.height / 2
                    )
                    Circle()
                        .fill(Color.white.opacity(star.currentOpacity))
                        .frame(width: star.currentSize, height: star.currentSize)
                        .position(p)
                        .blur(radius: star.distance < 50 ? 0.5 : 0)
                }
                
                // top bottom gradient
                AnimatedTopBottomView()
            }
            .ignoresSafeArea()
        }
//        .zIndex(-100)
    }
}



// Simple exploding shard effect
struct ExplodeEffect: View {
    struct Shard: Identifiable {
        let id = UUID()
        let angle: Double
        let distance: CGFloat
        let size: CGFloat
        let delay: Double
        let lifetime: Double
    }
    
    var baseColor: Color
    var shardCount: Int = 24
    
    @State private var shards: [Shard] = []
    @State private var progress: CGFloat = 0
    @State private var fade: Double = 1
    
    var body: some View {
        ZStack {
            ForEach(shards) { s in
                Circle()
                    .fill(baseColor.opacity(0.85))
                    .frame(width: s.size, height: s.size)
                    .offset(
                        x: cos(s.angle) * s.distance * progress,
                        y: sin(s.angle) * s.distance * progress
                    )
                    .opacity(fade)
                    .blur(radius: 0.5 + 8 * progress)
                    .animation(.easeOut(duration: s.lifetime).delay(s.delay), value: progress)
                    .animation(.linear(duration: s.lifetime).delay(s.delay), value: fade)
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            // Build shards with light randomness
            shards = (0..<shardCount).map { i in
                let angle = Double(i) / Double(shardCount) * .pi * 2
                          + Double.random(in: -0.18...0.18)
                return Shard(
                    angle: angle,
                    distance: CGFloat.random(in: 120...240),
                    size: CGFloat.random(in: 5...14),
                    delay: Double.random(in: 0.0...0.05),
                    lifetime: Double.random(in: 0.45...0.7)
                )
            }
            // Kick it
            progress = 1
            fade = 0
        }
    }
}





#Preview {
    MainTutorialView(onComplete: {})
        .environmentObject(MuteStore())
}
