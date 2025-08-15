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
    
    @State private var selection = 1

    @State private var lastHapticTime: Date = .distantPast
    @State private var holdWork: DispatchWorkItem? = nil
    @State private var isPressing = false
    let hapticInterval: TimeInterval = 0.2
    
    @State private var moveToResultView = false

    var body: some View {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height

        NavigationStack {
            GeometryReader { geo in
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
                    .position(x: screenWidth/2, y: screenHeight/2.5)
                    
                    // indicators
                    HStack(spacing: 10) {
                        ForEach(0..<3) { i in
                            Circle()
                                .fill(i == selection ? Color.primary : Color.gray.opacity(0.4))
                                .frame(width: i == selection ? 12 : 8, height: i == selection ? 12 : 8)
                                .animation(.easeInOut(duration: 0.2), value: selection)
                        }
                    }
                    .position(x: screenWidth/2, y: screenHeight/3)
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
            HapticManager.impact(.heavy)
            print("playing haptic circle0")
        case "circle1":
            HapticManager.notification(.warning)
            print("playing haptic circle1")
        case "circle2":
            HapticManager.notification(.success)
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
