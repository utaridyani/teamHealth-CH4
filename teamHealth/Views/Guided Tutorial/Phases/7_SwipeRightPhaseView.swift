//
//  SwipeRightPhaseView.swift
//  test_haptics
//
//  Created by Utari Dyani Laksmi on 24/08/25.
//

import SwiftUI

struct SwipeRightPhaseView: View {
    @Binding var stars: [Star]
    
    let onComplete: () -> Void
    // track touches
    @State private var touches: [Int: CGPoint] = [:]

    // hold state
    @State private var threeIDs: Set<Int> = []
    @State private var threeStartPositions: [Int:CGPoint] = [:]
    @State private var threeHoldWork: DispatchWorkItem?
    @State private var threeFingersHold = false

    let threeHoldDuration: TimeInterval = 2.0
    let threeMoveTolerance: CGFloat = 30
    
    // hint offset
    @State private var hintOffsetX: CGFloat = 0
    private let hintDistance: CGFloat = 200
    private let hintDuration: Double = 1.0
    
    @State private var blink = false
    @State private var offset = false
    

    var body: some View {
        let screenHeight = UIScreen.main.bounds.height
        let screenWidth = UIScreen.main.bounds.width
        
        let labelWidth = screenWidth * 0.6
        
        NavigationStack {
            ZStack {
                AmbientDecor(stars: $stars)
                
                if threeFingersHold {
                    AnimatedArrow(
                        length: screenWidth * 0.5,
                        color: .gray,
                        lineWidth: 2,
                        armed: $threeFingersHold
                    )
                    .position(x: screenWidth/2.8, y: screenHeight * 0.32)
//                    .offset(x: hintOffsetX-50)
                    .zIndex(11)
                    .transition(.opacity)
                }
                
                Text(threeFingersHold ? "Then swipe right" : "Long press with three fingers\nto close the vibration space")
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(
                      LinearGradient(
                        colors: [Color.white, Color.white.opacity(0.5)],
                        startPoint: .top,
                        endPoint: .bottom
                      )
                    )
                    .frame(width: labelWidth, alignment: .leading)
                    .position(x: screenWidth/2.6, y:screenHeight/2.5)
                    .transition(.opacity)
                    .zIndex(10)
                    
                
                Circle()
                    .fill(Color.gray)
                    .opacity(blink ? 1.0 : 0.4)
                    .blur(radius: 7)
                    .frame(width: screenWidth/13)
                    .position(x: screenWidth/3.5, y:screenHeight*0.56)
                    .offset(x: threeFingersHold ? hintDistance : 0)
                    .animation(.easeInOut(duration: hintDuration), value: threeFingersHold)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                                   value: blink)
                Circle()
                    .fill(Color.gray)
                    .opacity(blink ? 1.0 : 0.4)
                    .blur(radius: 7)
                    .frame(width: screenWidth/13)
                    .position(x: screenWidth/6, y:screenHeight*0.65)
                    .offset(x: threeFingersHold ? hintDistance : 0)
                    .animation(.easeInOut(duration: hintDuration), value: threeFingersHold)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                                   value: blink)
                Circle()
                    .fill(Color.gray)
                    .opacity(blink ? 1.0 : 0.4 )
                    .blur(radius: 7)
                    .frame(width: screenWidth/13)
                    .position(x: screenWidth/2.5, y:screenHeight*0.65)
                    .offset(x: threeFingersHold ? hintDistance : 0)   // 👈 drive by threeFingersHold
                    .animation(.easeInOut(duration: hintDuration), value: threeFingersHold)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                                   value: blink)

                // Full screen multitouch catcher
                MultiTouchView(
                    onChange: { newTouches in
                        handleTouches(newTouches)
                    },
                    isArmed: { threeFingersHold },
                    onRight: {
    //                    go to main menu after the
                        onComplete()
                        print("Three-finger swipe right triggered")
                    }
                )
                .ignoresSafeArea()
            }
            .onChange(of: threeFingersHold) { _, newValue in
                withAnimation(.easeInOut(duration: hintDuration)) {
                    offset = true
                    hintOffsetX = hintDistance
                }
            }
//            .navigationDestination(isPresented: $goNext) {
//                MainMenuView()
//            }
            .onAppear {
                blink = true
            }
        }
    }

    // MARK: - Hold logic
    private func handleTouches(_ newTouches: [Int: CGPoint]) {
        touches = newTouches
        let ids = Set(newTouches.keys)
        if ids.count == 3 {
            if ids != threeIDs {
                // new 3-finger set: reset hold
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
                        
                        withAnimation { self.threeFingersHold = true }
                        print("Three-finger hold armed")
                    }
                }
                threeHoldWork = work
                DispatchQueue.main.asyncAfter(deadline: .now() + threeHoldDuration, execute: work)
            }
        } else {
            // not exactly 3 touches → reset
            threeHoldWork?.cancel()
            threeHoldWork = nil
            threeIDs = []
            threeStartPositions = [:]
            if threeFingersHold {
                withAnimation {
                    threeFingersHold = false
                    hintOffsetX = 0
                    offset = false
                }
            }
        }
    }
}

private struct AnimatedArrow: View {
    var length: CGFloat = 200
    var color: Color = .white
    var lineWidth: CGFloat = 1.0

    @Binding var armed: Bool
    @State private var progress: CGFloat = 0.0

    var body: some View {
        ArrowShape(length: length, headSize: 10)
            .trim(from: 0, to: progress) //
            .stroke(color, style: StrokeStyle(
                lineWidth: lineWidth,
                lineCap: .round,
                lineJoin: .round,
                miterLimit: 1
            ))
            .shadow(color: color.opacity(0.6), radius: 0)
            .frame(width: length + 20, height: 40)
            .onChange(of: armed) { _, newValue in
                withAnimation(.easeInOut(duration: 0.9)) {
                    progress = newValue ? 1.0 : 0.0
                }
            }
            .onAppear {
                progress = armed ? 1.0 : 0.0
            }
    }
}

private struct ArrowShape: Shape {
    var length: CGFloat
    var headSize: CGFloat   // tip size

    func path(in rect: CGRect) -> Path {
        let midY = rect.midY
        let jx   = max(0, length - headSize)         // junction of shaft & head
        let tipX = length
        let upY  = midY - headSize * 0.6
        let dnY  = midY + headSize * 0.6

        var p = Path()
        // shaft → tip → lower corner → tip → upper corner
        p.move(to: CGPoint(x: 0,    y: midY))
        p.addLine(to: CGPoint(x: jx, y: midY))       // shaft
        p.addLine(to: CGPoint(x: tipX, y: midY))     // to tip
        p.addLine(to: CGPoint(x: jx,   y: dnY))      // tip → lower corner
        p.move(to: CGPoint(x: tipX, y: midY))        // back to tip (move, not line)
        p.addLine(to: CGPoint(x: jx,   y: upY))      // tip → upper corner
        return p
    }
}
