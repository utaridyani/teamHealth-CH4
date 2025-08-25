//
//  TapGuidePhase.swift
//  test_haptics
//
//  Created by Utari Dyani Laksmi on 24/08/25.
//

import SwiftUI

struct TapGuidePhaseView: View {
    @Binding var stars: [Star]
    @StateObject private var bubbleManager = BubblePhysicsManager()

    // touch state
    @State private var touches: [Int: CGPoint] = [:]
    @State private var lastTimes: [Int: Date] = [:]
    @State private var hasUserInteracted = false

    // fake hold state
    private let fakeID: Int = -9999
    @State private var fakePoint: CGPoint = .zero
    @State private var showingFakeHold = true

    // text state
    private let messages = ["Or, just tap it\nfor a quick feel", "Move around\nto feel the sensation", "Did you feel\nthe difference?"]
    @State private var showText = false
    @State private var messageIndex = 0
    
    // haptic
    let hapticInterval: TimeInterval = 0.2
    
    // next state
    @State private var next = false
    var onFinishedSlides: () -> Void

    // timers
    private let bubbleTimer = Timer.publish(every: 1.0/60.0, on: .main, in: .common).autoconnect()

    var body: some View {
        let screenHeight = UIScreen.main.bounds.height
        
        GeometryReader { geo in
            ZStack {
                // background
                AmbientDecor(stars: $stars)

                // bubbles
                ForEach(bubbleManager.touchBubbles) { bubble in
                    BubbleGlowView(bubble: bubble)
                }

                // instructuion text
                if showText {
                    Text(messages[messageIndex])
                        .font(.system(size: 17, weight: .regular, design: .rounded))
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(
                          LinearGradient(
                            colors: [Color.white, Color.white.opacity(0.5)],
                            startPoint: .top,
                            endPoint: .bottom
                          )
                        )
                        .transition(.opacity)
                        .zIndex(10)
                        .padding(.bottom, screenHeight-(screenHeight/1.5))
                }

                // multitouch catcher
                TouchCatcherView { newTouches in
                    handleTouches(newTouches)
                }
                .ignoresSafeArea()
            }
            .onAppear {
                // fake hold to create the bubble when appear
                fakePoint = CGPoint(x: geo.size.width/2, y: geo.size.height/2)
                showingFakeHold = true
                bubbleManager.updateTouches([fakeID: fakePoint], sphereType: .twilight)

                // after 3s - insturksi 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                    showText = true
                    messageIndex = 0

                    // instruksi 2
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                        messageIndex = 1

                        // instruksi 3
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            messageIndex = 2
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                next = true
                            }
                        }
                    }
                }
            }
            .onReceive(bubbleTimer) { _ in
                bubbleManager.updatePhysics()
            }
            .onDisappear {
                bubbleManager.clearAll()
            }
            .onChange(of: next) { _, newValue in
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    onFinishedSlides()
                }
            }
        }
        .highPriorityGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { v in
                    hasUserInteracted = true
                    showingFakeHold = false
                    bubbleManager.updateTouches([0: v.location], sphereType: .twilight)
                    playHapticIfNeeded(for: 0)
                }
                .onEnded { _ in
                    bubbleManager.updateTouches([:], sphereType: .twilight)
                    lastTimes[0] = nil
                }
        )
    }
    
    private func playHapticIfNeeded(for id: Int) {
        let now = Date()
        let last = lastTimes[id] ?? .distantPast
        if now.timeIntervalSince(last) > hapticInterval {
            HapticManager.playAHAP(named: "twilight")
            lastTimes[id] = now
            print("haptic played")
        }
    }

    // MTouch handling
    private func handleTouches(_ newTouches: [Int: CGPoint]) {
        // first real user touchto kill fake hold

        if !newTouches.isEmpty {
            hasUserInteracted = true
            showingFakeHold = false
            
            for id in newTouches.keys {
                playHapticIfNeeded(for: id)
            }
        }
        
        lastTimes = lastTimes.filter { newTouches.keys.contains($0.key) }

        var effective = newTouches
        if showingFakeHold {
            effective[fakeID] = fakePoint
        }

        bubbleManager.updateTouches(effective, sphereType: .twilight)
    }
    
    private struct BubbleGlowView: View {
        let bubble: TouchBubble

        var body: some View {
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
    }
}


// UIKit bridge to catch multiple touches
private struct TouchCatcherView: UIViewRepresentable {
    var onChange: ([Int: CGPoint]) -> Void

    func makeUIView(context: Context) -> TouchCatcher {
        TouchCatcher(onChange: onChange)
    }
    func updateUIView(_ uiView: TouchCatcher, context: Context) {}

    final class TouchCatcher: UIView {
        private let onChange: ([Int: CGPoint]) -> Void
        init(onChange: @escaping ([Int: CGPoint]) -> Void) {
            self.onChange = onChange
            super.init(frame: .zero)
            isMultipleTouchEnabled = true
            backgroundColor = .clear
        }
        required init?(coder: NSCoder) { fatalError() }

        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) { send(event) }
        override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) { send(event) }
        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { send(event) }
        override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { send(event) }

        private func send(_ event: UIEvent?) {
            var map: [Int: CGPoint] = [:]
            if let all = event?.allTouches {
                for t in all where t.phase != .ended && t.phase != .cancelled {
                    map[t.hash] = t.location(in: self)
                }
            }
            onChange(map)
        }
    }
}
