//
//  LastTextPhaseView.swift
//  test_haptics
//
//  Created by Utari Dyani Laksmi on 24/08/25.
//

import SwiftUI

struct LastTextPhaseView: View {
    @Binding var stars: [Star]
    var onFinishedSlides: () -> Void
    
    // text state
    private let messages = ["Hopefully the vibration\nresonates your state of mind", "One last thing"]
    @State private var showText = false
    @State private var messageIndex = 0
    
    var body: some View {
        ZStack {
            AmbientDecor(stars: $stars)
            
            if showText {
                ZStack {
                    if messageIndex == 0 {
                        Text(messages[0])
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
                            .fadeInOnAppear(delay: 0.1, duration: 0.8)
                    }
                    if messageIndex == 1 {
                        Text(messages[1])
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
                            .fadeInOnAppear(delay: 0.1, duration: 0.8)
                    }
                }

            }
        }
        .onAppear {
            // after 3s - insturksi 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                showText = true
                messageIndex = 0

                // instruksi 2
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    messageIndex = 1

                    // next
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        onFinishedSlides()
                    }
                }
            }
        }
    }
}
