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

    var body: some View {
        ZStack {
            Color(red: 25/255, green: 25/255, blue: 25/255)
                .ignoresSafeArea()

            LoopingVideo(resource: "Buzzle_Logo_Motion")
                .ignoresSafeArea()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                onFinished()
            }
        }
    }
}
//
//#Preview {
//    SplashScreenView()
//}

