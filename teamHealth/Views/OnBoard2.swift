//
//  OnBoard2.swift
//  buzzle
//
//  Created by Felly on 18/08/25.
//
import SwiftUI
import Lottie

struct OnBoard2: View {
    
    @State private var current = 0
    let dotCount = 3
    
    var body: some View {
        ZStack {
            Color.blackeu.ignoresSafeArea()
            VStack {
                Spacer()
                
                Text("A rhythm to settle")
                    .font(.body)
                    .foregroundColor(.whiteu)
//                    .padding(.bottom, 100)

                LottieView(name: "Boba", loopMode: .loop, playOnAppear: true)
                    .frame(width: 400, height: 400)
                    
                
                
                Text("""
                     Gentle, repeated motion
                     offers your mind a room to ease anxiety and settle your heart
                     """)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)
//                    .padding(.top,5 )
                    .foregroundStyle(.white)
                
                Spacer()
                
                }
            
            }
//            .padding()
        }
    }

#Preview {
    OnBoard2()
}
