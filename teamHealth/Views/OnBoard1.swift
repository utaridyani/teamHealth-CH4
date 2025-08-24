//
//  OnBoard1.swift
//  buzzle
//
//  Created by Felly on 18/08/25.
//
import SwiftUI
import Lottie

struct OnBoard1: View {
    
    @State private var current = 0
    let dotCount = 3
    
    var body: some View {
        ZStack {
            Color.blackeu
                .ignoresSafeArea()
                .padding(.leading, -150)
            VStack {
                Spacer()
                
                Text("When it’s all too much...")
                    .font(.body)
                    .foregroundColor(.whiteu)
                    .padding(.bottom, 50)

                LoopingVideo(resource: "mind3d")
                    .frame(width: 320, height: 320)
                
                Text("""
some feelings don’t fit 
inside a sentence, not even a word
""")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)
                    .padding(.top, 50)
                    .foregroundStyle(.white)
                
                Spacer()
                
                }
            
            }
//            .padding()
        }
    }

#Preview {
    OnBoard1()
}
