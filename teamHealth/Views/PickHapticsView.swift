//
//  PickHapticsView.swift
//  teamHealth
//
//  Created by Utari Dyani Laksmi on 14/08/25.
//

import SwiftUI
import SwiftData


struct PickHapticsView: View {
    @State private var redRectFrame: CGRect = .zero
    @State private var yellowRectFrame: CGRect = .zero
    @State private var grayRectFrame: CGRect = .zero
    @State private var greenRectFrame: CGRect = .zero
    @State private var brownRectFrame: CGRect = .zero
    @State private var indigoRectFrame: CGRect = .zero
    @State private var position: CGPoint? = nil
    @State private var fingerColor: Color = .clear
    @State private var scale : CGFloat = 1.0
    @State private var fingerInside = false
    @State private var lastHapticTime: Date = .distantPast
    @State private var shuffledColors: [Color] = []
    @State private var rectFrames: [CGRect] = Array(repeating: .zero, count: 6)
    
    let colors: [Color] = [.red, .yellow, .gray, .green, .brown, .indigo]
    let hapticInterval: TimeInterval = 0.2
    
    
    @State private var holdStartTime: Date?
    @State private var holdRectIndex: Int? = nil
    
    @EnvironmentObject var hapticData: HapticData
    
    @State private var navigateToResult = false
    @State private var holdInstructionText = false

    
    var body: some View {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        NavigationStack {
            ZStack {
                Rectangle()
                    .fill(Color.white)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let now = Date()
                                
                                // the circle
                                if position == nil {
                                    position = value.location
                                }
                                
                                position = value.location
                                
                                for (index, frame) in rectFrames.enumerated() {
                                    if frame.contains(value.location) {
                                        if now.timeIntervalSince(lastHapticTime) > hapticInterval {
                                            lastHapticTime = now
                                            let color = shuffledColors[index]
                                            fingerColor = color
                                            triggerHaptic(for: color)
                                            
                                            // hold detection if not already started for this rect
                                            if holdRectIndex != index {
                                                holdRectIndex = index
                                                holdStartTime = Date()
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                                    if holdRectIndex == index,
                                                       let start = holdStartTime {
                                                        let gap = Date().timeIntervalSince(start)
                                                        
                                                        if gap >= 0.2 {
                                                            // show hold instruction text
                                                            holdInstructionText = true
                                                            
                                                            // wait for 2 second
                                                            // hide text
                                                            
                                                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                                                    holdInstructionText = false
                                                            }
                                                        }
                                                        
                                                    }
                                                }
                                                
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                                    if holdRectIndex == index,
                                                       let start = holdStartTime {
                                                        let gap = Date().timeIntervalSince(start)
                                                         
                                                        if gap >= 3 {
                                                             // save dsata
                                                             hapticData.selectedHapticName = hapticName(for: color)
                                                             hapticData.selectedColor = color
                                                             print("Saved: \(hapticName(for: color)), \(color.description)")
                                                             
                                                             
                                                             // next view
                                                             navigateToResult = true
                                                        }
                                                        
                                                    }
                                                }
                                            }
                                        }
                                        return
                                    }
                                }
                                holdRectIndex = nil
                                holdStartTime = nil
                                
                                print("Finger outside all squares")
                            }
                            .onEnded { _ in
                                print("Drag ended")
                                fingerColor = Color.clear
                                holdRectIndex = nil
                                holdStartTime = nil
                            }
                    )
                
                
                // grid of rectangles using shuffled colors
                // used to differentiate haptics and bubble color in every area
                VStack(spacing: 0) {
                    ForEach(0..<3) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<2) { col in
                                let idx = row * 2 + col
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(width: screenWidth * 0.5, height: screenHeight * (1.0/3.0))
                                    .allowsHitTesting(false)
                                    .overlay(
                                        GeometryReader { geo in
                                            Color.clear
                                                .onAppear {
                                                    DispatchQueue.main.async {
                                                        if rectFrames.indices.contains(idx) {
                                                            rectFrames[idx] = geo.frame(in: .global)
                                                        }
                                                    }
                                                }
                                        }
                                    )
                            }
                        }
                    }
                }
                
                GeometryReader { geo in
                    ZStack {
                        if let pos = position {
                            Circle()
                                .fill(fingerColor)
                                .frame(width: 80, height: 80)
                                .position(pos)
                                .allowsHitTesting(false)
                            
                            if holdInstructionText {
                                Text("hold to choose the haptics")
                                    .position(x:pos.x, y:pos.y - 50)
                            }
                        }
                    }
                }
            }
            .ignoresSafeArea()
            .navigationBarBackButtonHidden()
            .onAppear {
                shuffledColors = colors.shuffled()
                rectFrames = Array(repeating: .zero, count: colors.count)
            }
            .navigationDestination(isPresented: $navigateToResult) {
                ResultScreenView()
                    .environmentObject(hapticData)
            }
        }


    }
    
    func triggerHaptic(for color: Color) {
        switch color {
        case .red:
            HapticManager.notification(.success)
        case .yellow:
            HapticManager.selection()
        case .gray:
            HapticManager.notification(.warning)
        case .green:
            HapticManager.notification(.error)
        case .brown:
            HapticManager.impact(.heavy)
        case .indigo:
            HapticManager.impact(.soft)
        default:
            break
        }
    }
    
    
    func hapticName(for color: Color) -> String {
        switch color {
        case .red: return "Success"
        case .yellow: return "Selection"
        case .gray: return "Warning"
        case .green: return "Error"
        case .brown: return "Heavy Impact"
        case .indigo: return "Soft Impact"
        default: return "Unknown"
        }
    }
}

#Preview {
    PickHapticsView()
        .environmentObject(HapticData())
}
