//
//  SplashScreenView.swift
//  teamHealth
//
//  Created by Utari Dyani Laksmi on 25/08/25.
//

import SwiftUI
import AVKit

struct SplashScreenView: View {
    let onFinished: () -> Void
    @State private var showOnBoard = false
    @State private var hideOnBoard = false

    var body: some View {
        ZStack {
            Color(red: 25/255, green: 25/255, blue: 25/255)
                .ignoresSafeArea()

            if showOnBoard && !hideOnBoard {
                OnBoard0()
                    .transition(.opacity) // fade in/out
            } else if !showOnBoard {
                LoopingVideo(resource: "Buzzle_Logo_Motion")
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 1.0), value: showOnBoard)
        .animation(.easeInOut(duration: 0.5), value: hideOnBoard)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    showOnBoard = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        hideOnBoard = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        onFinished()
                    }
                }
            }
        }
    }
}
//
//#Preview {
//    SplashScreenView()
//}

