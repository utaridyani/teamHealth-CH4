//
//  OnBoard3.swift
//  buzzle
//
//  Created by Felly on 18/08/25.
//

import SwiftUI
import Lottie

struct OnBoard3: View {
    
    @State private var current = 0
//    let dotCount = 3
    
    var body: some View {
//        let screenWidth = UIScreen.main.bounds.width
//        let screenHeight = UIScreen.main.bounds.height
        
        
            ZStack {
                Color.blackeu
                    .edgesIgnoringSafeArea(.vertical)
                    .padding(.trailing, -150)
                VStack {
                
    //            Image("pearl")
    //                .resizable()
    ////                .padding(.top, 0)
    //                .frame(width: 600, height: 600)
                
                ZStack {
                    Text("Express without a word")
                        .font(.body)
                        .foregroundColor(.whiteu)
                        .padding(.bottom, 480)
                    
    //                ZStack {
    //                    Circle()
    //                        .stroke(style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round))
    //                        .foregroundColor(.whiteu)
    //                        .frame(width: 200, height:200)
    //
    //                    Circle()
    //                        .stroke(style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round))
    //                        .fill(Color.whiteu)
    //                        .frame(width: 270, height: 270)
    //                }
                    
                    LottieView(name: "tap", loopMode: .loop, playOnAppear: true)
                        .frame(width: 700, height: 700)
                        .padding(.horizontal, -150)
                        
                        
                    
                    
                    Text(("""
    Say it with a living rhythm,
    when words won’t land.
    """))
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)
                    .padding(.top, 450)
                    .foregroundStyle(.whiteu)
                }
                    
                }
        }
    }
}

#Preview {
    OnBoard3()
}
