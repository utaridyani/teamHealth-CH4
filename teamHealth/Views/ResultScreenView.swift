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
    @State private var fingerPosition = "red"
    let threeHoldDuration: TimeInterval = 2.0
    let threeMoveTolerance: CGFloat = 30
    
    @State private var backToMainMenu = false
//    @State private var goChooseHaptics = false

    var body: some View {
//        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        NavigationStack {
            ZStack {
                // bg
                Color.white.ignoresSafeArea()


                // multitouch tracker (transparent, full screen)
                MultiTouchView(
                    
                    onChange: { newTouches in
                        touches = newTouches

                        let circle = selectedHaptic.selectedCircle ?? "circle0"
                        let now = Date()
                        
                        for (id, point) in newTouches {
                            if now.timeIntervalSince(lastTimes[id] ?? .distantPast) > hapticInterval {
                                lastTimes[id] = now
                                
                                if let a = area(for: point.y, totalHeight: screenHeight) {
                                    triggerHapticByCircle(for: circle, area: a)
                                    print("yeay here")
                                }

                                else {
                                    print("not there yet")
                                }
                                
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
                    onRight: {
                        print("swipe right")
                        HapticManager.selection()
                        threeFingersHold = false
                        backToMainMenu = true
                    }
//                    onLeft: {
//                        print("swipe left")
//                        HapticManager.selection()
//                        threeFingersHold = false
//                        goHome = true
//                    },
//                    onUp: {
//                        print("swipe up")
//                        HapticManager.selection()
//                        goChooseHaptics = true
//                    }
                )
                .ignoresSafeArea()

                // Up to two circles for two fingers
                ForEach(Array(touches.keys.prefix(2)), id: \.self) { id in
                    if let p = touches[id] {
                        
                        Circle()
                            // change the color based on selected color after this
                            .fill(selectedHaptic.selectedColor ?? .red)
                            .frame(width: 80, height: 80)
                            .position(x: p.x, y: (p.y - 40))
                            .allowsHitTesting(false)
                            .shadow(radius: 4)
                    }
                }

                if threeFingersHold {
                    let widthScreen = UIScreen.main.bounds.width
                    Text("Swipe right to go back")
                        .position(x:widthScreen/2, y:50)
                }
            }
            .ignoresSafeArea()
            .navigationBarBackButtonHidden(true)
            .navigationDestination(isPresented: $backToMainMenu) {
                MainMenuView()
            }
//            .navigationDestination(isPresented: $goChooseHaptics) {
//                ContentView()
//                    .environmentObject(hapticData)
//            }
        }
        
    }
    
    // to detect where the touch point is
    // the screen will be divided into 3 parts
    func area(for y: CGFloat, totalHeight: CGFloat) -> Int? {
        guard totalHeight > 0 else { return nil }
        let h = totalHeight / 3
        switch y {
        // top
        case 0..<h:
            return 0
        // middle
        case h..<(2*h):
            return 1
        // bottom
        case (2*h)...:
            return 2
        default:
            return nil
        }
    }
    
    
    // haptics trigger
    func triggerHapticByCircle(for circle: String, area: Int) {
        switch circle {
        case "circle0":
            switch area {
            case 0:
                HapticManager.playAHAP(named: "heavy25")
                print("playing haptic circle0 - 0")
            case 1:
                HapticManager.playAHAP(named: "heavy25_75")
                print("playing haptic circle0 - 1")
            case 2:
                HapticManager.playAHAP(named: "heavy25_50")
                print("playing haptic circle0 - 2")
            default:
                break
            }
            

        case "circle1":
            switch area {
            case 0:
                HapticManager.playAHAP(named: "heavy50")
                print("playing haptic circle1 - 0")
            case 1:
                HapticManager.playAHAP(named: "heavy50_75")
                print("playing haptic circle1 - 1")
            case 2:
                HapticManager.playAHAP(named: "heavy50_50")
                print("playing haptic circle1 - 2")
            default:
                break
            }

        case "circle2":
            switch area {
            case 0:
                HapticManager.playAHAP(named: "heavy75")
                print("playing haptic circle2 - 0")
            case 1:
                HapticManager.playAHAP(named: "heavy75_75")
                print("playing haptic circle2 - 1")
            case 2:
                HapticManager.playAHAP(named: "heavy75_50")
                print("playing haptic circle2 - 2")
            default:
                break
            }

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


#Preview {
    ResultScreenView()
        .environmentObject(SelectedHaptic())
}
