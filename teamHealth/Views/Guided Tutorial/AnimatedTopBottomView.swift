//
//  AnimatedTopBottomView.swift
//  teamHealth
//
//  Created by Utari Dyani Laksmi on 19/08/25.
//

import SwiftUI

struct AnimatedTopBottomView: View {
    @State private var phase: CGFloat = 0
    @State private var randomOffsets: [CGFloat] = [0, 0, 0]
    
    var body: some View {
        GeometryReader { geo in
            let screenWidth = geo.size.width
            let screenHeight = geo.size.height
            
            ZStack {
//                Color(red:25/255, green:25/255, blue:25/255)
                
                // bottom
                blob(
                    gradient: EllipticalGradient(
                        stops: [
                            .init(color: Color(red: 0.27, green: 0.49, blue: 0.79), location: 0),
                            .init(color: Color(red: 0.53, green: 0.05, blue: 0.27).opacity(0.5), location: 1)
                        ],
                        center: UnitPoint(x: 0.8, y: 0.32)
                    ),
                    size: 320,
                    baseX: screenWidth * 0.2,
                    baseY: screenHeight + 90,
                    amplitude: 120,
                    speed: 0.6,
                    phase: phase,
                    randomOffset: randomOffsets[0]
                )
                
                blob(
                    gradient: EllipticalGradient(
                        stops: [
                            .init(color: Color(red: 0.37, green: 0.49, blue: 0.69), location: 0),
                            .init(color: Color(red: 0, green: 0.34, blue: 0.58).opacity(0.5), location: 1)
                        ],
                        center: UnitPoint(x: 0.77, y: 0.36)
                    ),
                    size: 240,
                    baseX: screenWidth * 0.5,
                    baseY: screenHeight + 100,
                    amplitude: 180,
                    speed: 0.8,
                    phase: phase + .pi/3,
                    randomOffset: randomOffsets[1]
                )
                
                blob(
                    gradient: EllipticalGradient(
                        stops: [
                            .init(color: Color(red: 0.37, green: 0.49, blue: 0.89), location: 0),
                            .init(color: Color(red: 0.59, green: 0.4, blue: 0.07).opacity(0.5), location: 1)
                        ],
                        center: UnitPoint(x: 0.7, y: 0.53)
                    ),
                    size: 260,
                    baseX: screenWidth * 0.8,
                    baseY: screenHeight + 80,
                    amplitude: 100,
                    speed: 0.5,
                    phase: phase + .pi/6,
                    randomOffset: randomOffsets[2]
                )
                
                // top
                blob(
                    gradient: EllipticalGradient(
                        stops: [
                            .init(color: Color(red: 0.37, green: 0.49, blue: 0.69), location: 0),
                            .init(color: Color(red: 0.53, green: 0.05, blue: 0.27).opacity(0.5), location: 1)
                        ],
                        center: UnitPoint(x: 0.8, y: 0.32)
                    ),
                    size: 320,
                    baseX: screenWidth * 0.8,
                    baseY: -90,
                    amplitude: 120,
                    speed: 0.6,
                    phase: phase,
                    randomOffset: randomOffsets[0]
                )
                blob(
                    gradient: EllipticalGradient(
                        stops: [
                            .init(color: Color(red: 0.37, green: 0.49, blue: 0.99), location: 0),
                            .init(color: Color(red: 0, green: 0.34, blue: 0.58).opacity(0.5), location: 1)
                        ],
                        center: UnitPoint(x: 0.77, y: 0.36)
                    ),
                    size: 240,
                    baseX: screenWidth * 0.5,
                    baseY: -100,
                    amplitude: 180,
                    speed: 0.8,
                    phase: phase + .pi/3,
                    randomOffset: randomOffsets[1]
                )
                blob(
                    gradient: EllipticalGradient(
                        stops: [
                            .init(color: Color(red: 0.37, green: 0.49, blue: 0.69), location: 0),
                            .init(color: Color(red: 0.59, green: 0.4, blue: 0.07).opacity(0.5), location: 1)
                        ],
                        center: UnitPoint(x: 0.7, y: 0.53)
                    ),
                    size: 260,
                    baseX: screenWidth * 0.2,
                    baseY: -80,
                    amplitude: 100,
                    speed: 0.5,
                    phase: phase + .pi/6,
                    randomOffset: randomOffsets[2]
                )
                
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .onAppear {
                // continuous looping phase
                withAnimation(.linear(duration: 5).repeatForever(autoreverses: false)) {
                    phase = .pi * 2
                }
                // random wander every 6s
                Timer.scheduledTimer(withTimeInterval: 6, repeats: true) { _ in
                    withAnimation(.easeInOut(duration: 6)) {
                        randomOffsets = randomOffsets.map { _ in
                            CGFloat.random(in: -150...150)
                        }
                    }
                }
            }
        }
    }
    
    func blob(gradient: EllipticalGradient,
              size: CGFloat,
              baseX: CGFloat,
              baseY: CGFloat,
              amplitude: CGFloat,
              speed: CGFloat,
              phase: CGFloat,
              randomOffset: CGFloat) -> some View  {
        
        Circle()
            .fill(gradient)
            .blur(radius: 50)
            .opacity(0.2)
            .shadow(color: .white.opacity(0.2), radius: 2.25)
            .frame(width: size, height: size)
            .position(
                x: baseX + amplitude * sin(speed * phase) + randomOffset,
                y: baseY
            )
    }
}


#Preview {
    AnimatedTopBottomView()
}
