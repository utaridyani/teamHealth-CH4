//
//  MainMenuView.swift
//  test_haptics
//
//  Created by Utari Dyani Laksmi on 14/08/25.
//

import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject var hapticData: HapticData // no longer used
    @EnvironmentObject var selectedHaptic: SelectedHaptic
    
    @State private var selection = 0

    @State private var lastHapticTime: Date = .distantPast
    @State private var holdWork: DispatchWorkItem? = nil
    @State private var isPressing = false
    let hapticInterval: TimeInterval = 0.2
    
    @State private var moveToResultView = false
    
    @State private var starPoints: [CGPoint] = []
    @State private var starPoints2: [CGPoint] = []
    @State private var didMakeStars = false

    var body: some View {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height

        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    // background color
//                    LinearGradient(
//                        gradient: Gradient(colors: [
//                            Color(red: 0, green: 0, blue: 0),
//                            Color(red: 255/255, green: 195/255, blue: 82/255)
//                        ]),
//                        startPoint: .topLeading,
//                        endPoint: .bottomTrailing
//                    )
//                    .ignoresSafeArea()
                    
                    // little stars - size 1
                    ForEach(0..<starPoints.count, id: \.self) { i in
                        Circle()
                            .fill(Color.white.opacity(0.9))
                            .frame(width: 1.2, height: 1.2)
                            .position(starPoints[i])
                    }
                    
                    // little stars - size 2
                    ForEach(0..<starPoints2.count, id: \.self) { i in
                        Circle()
                            .fill(Color.white.opacity(0.9))
                            .frame(width: 2, height: 2)
                            .position(starPoints2[i])
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
                        
                        // indicators
//                        HStack(spacing: 10) {
//                            ForEach(0..<3) { i in
//                                Circle()
//                                    .fill(i == selection ? Color.white : Color.gray.opacity(0.4))
//                                    .frame(width: i == selection ? 12 : 8, height: i == selection ? 12 : 8)
//                                    .animation(.easeInOut(duration: 0.2), value: selection)
//                            }
//                        }
//                        .position(x: screenWidth/2, y: screenHeight/3)
                        
                    }
                }
                .onAppear {
                    // generate stars
                    if !didMakeStars {
                        let w = UIScreen.main.bounds.width
                        let h = UIScreen.main.bounds.height
                        starPoints = (0..<100).map { _ in
                            CGPoint(x: CGFloat.random(in: 0...w),
                                    y: CGFloat.random(in: 0...h))
                        }
                        starPoints2 = (0..<20).map { _ in
                            CGPoint(x: CGFloat.random(in: 0...w),
                                    y: CGFloat.random(in: 0...h))
                        }
                        didMakeStars = true
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
                            Gradient.Stop(color: .black, location: 0.00),
                            Gradient.Stop(color: Color(red: 0, green: 0.3, blue: 0.9).opacity(0.7), location: 1),
//                            Gradient.Stop(color: Color(red: 0, green: 0.3, blue: 0.9).opacity(1), location: 1.00),
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
