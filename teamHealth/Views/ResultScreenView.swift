//
//  ResultScreenView.swift
//  teamHealth
//
//  Created by Utari Dyani Laksmi on 14/08/25.
//

import SwiftUI
import SwiftData

struct ResultScreenView: View {
    @EnvironmentObject var hapticData: HapticData // no longer used
    @EnvironmentObject var selectedHaptic: SelectedHaptic

    // multitouch state
    @State private var touches: [Int: CGPoint] = [:]       // touchID -> position
    @State private var lastTimes: [Int: Date] = [:]         // per-touch throttle
    @State private var holdThreeFingers = false
    let hapticInterval: TimeInterval = 0.2
    
    
    @State private var threeIDs: Set<Int> = []
    @State private var threeStartPositions: [Int:CGPoint] = [:]
    @State private var threeHoldWork: DispatchWorkItem?
    @State private var threeFingersHold = false
    let threeHoldDuration: TimeInterval = 2.0
    let threeMoveTolerance: CGFloat = 30
    
    @State private var goHome = false
//    @State private var goChooseHaptics = false

    var body: some View {
        NavigationStack {
            ZStack {
                // bg
                Color.white.ignoresSafeArea()

                // multitouch tracker (transparent, full screen)
                MultiTouchView(
                    
                    onChange: { newTouches in
                        touches = newTouches

//                        let color = hapticData.selectedColor ?? .clear
                        let now = Date()
                        let circle = selectedHaptic.selectedCircle ?? "circle0"
                        
                        for (id, _) in newTouches {
                            if now.timeIntervalSince(lastTimes[id] ?? .distantPast) > hapticInterval {
                                lastTimes[id] = now
                                triggerHapticByCircle(for: circle)
                            }
                        }

                        // 3 fingers hold
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
                                        // set to true if ok
                                        self.threeFingersHold = true
                                        HapticManager.selection()
                                        print("3 fingers hold armed")
                                    }
                                }
                                threeHoldWork = work
                                DispatchQueue.main.asyncAfter(deadline: .now() + threeHoldDuration, execute: work)
                            }
                        } else {
                            // if no longer 3 fingers, set to false
                            threeHoldWork?.cancel(); threeHoldWork = nil
                            threeIDs = []
                            threeStartPositions = [:]
                            threeFingersHold = false
                        }
                    },
                    
                    // call the threeFingersHold if armed
                    isArmed: { threeFingersHold },
                    onLeft: {
                        print("swipe left")
                        HapticManager.selection()
                        threeFingersHold = false
                        goHome = true
                    },
                    onUp: {
                        print("swipe up")
                        HapticManager.selection()
//                        goChooseHaptics = true
                    }
                )
                .ignoresSafeArea()

                // Up to two circles for two fingers
                ForEach(Array(touches.keys.prefix(2)), id: \.self) { id in
                    if let p = touches[id] {
                        Circle()
                            // change the color based on selected color after this
                            .fill(Color.red)
                            .frame(width: 80, height: 80)
                            .position(p)
                            .allowsHitTesting(false)
                            .shadow(radius: 4)
                    }
                }
                
    //            if threeFingersHold {
    //                Text("Swipe")
    //            }
                
    //            ThreeFingerPanLeft(
    //                isArmed: { threeFingersHold },
    //                onLeft: {
    //                    print("3-finger LEFT swipe detected (undo)")
    //                    threeFingersHold = false // reset after action
    //                }
    //            )
    //            .frame(maxWidth: .infinity, maxHeight: .infinity)
    //            .ignoresSafeArea()
    //            .allowsHitTesting(true)
                
                
                if threeFingersHold {
                    let widthScreen = UIScreen.main.bounds.width
                    Text("Swipe up or left")
                        .position(x:widthScreen/2, y:50)
                }
            }
            .navigationBarBackButtonHidden(true)
            .navigationDestination(isPresented: $goHome) {
                MainMenuView()
            }
//            .navigationDestination(isPresented: $goChooseHaptics) {
//                ContentView()
//                    .environmentObject(hapticData)
//            }
        }
        
    }
    
    func triggerHapticByCircle(for circle: String) {
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

    // no longer used
    func triggerHaptic(for color: Color) {
        switch color {
        case .red:    HapticManager.notification(.success)
        case .yellow: HapticManager.selection()
        case .gray:   HapticManager.notification(.warning)
        case .green:  HapticManager.notification(.error)
        case .brown:  HapticManager.impact(.heavy)
        case .indigo: HapticManager.impact(.soft)
        default: break
        }
    }
}
