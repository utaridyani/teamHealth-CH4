//
//  IntensityView.swift
//  teamHealth
//
//  Created by Utari Dyani Laksmi on 20/08/25.
//

import SwiftUI



struct IntensityView: View {
    @State private var isMuted = false
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                isMuted.toggle()
            }
        }) {
            Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(.gray)
                .padding(40)
                .background(
                    Circle()
                        .fill(Color.black.opacity(0.85))
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 2)
                        )
                        .shadow(color: Color.white.opacity(0.05), radius: 10, x: 0, y: 0)
                )
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        IntensityView()
    }
}
