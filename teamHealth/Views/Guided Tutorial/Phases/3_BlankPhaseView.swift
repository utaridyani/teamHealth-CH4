//
//  BlankPhaseView.swift
//  test_haptics
//
//  Created by Utari Dyani Laksmi on 24/08/25.
//

import SwiftUI

struct BlankPhaseView: View {
    @Binding var stars: [Star]
    @State private var next = false
    var onFinishedSlides: () -> Void
    
    var body: some View {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        VStack {
            ZStack {
                AmbientDecor(stars: $stars)
                Text("Press and hold\nanywhere to feel\nthe vibration")
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
                    .fadeInOnAppear(delay: 0.1, duration: 0.8)
            }
        }
        .frame(width: screenWidth, height: screenHeight, alignment: .center)
        .background(Color(red: 25/255, green: 25/255, blue: 25/255))
        .ignoresSafeArea()
        .navigationBarBackButtonHidden()
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                next = true
            }
        }
        .onChange(of: next) { _, newValue in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                onFinishedSlides()
            }
        }
    }
}
