//
//  OnBoard1.swift
//  buzzle
//
//  Created by Felly on 18/08/25.
//

import SwiftUI

struct OnBoard0: View {
    var body: some View {
        ZStack {
            Color.blackeu
                .edgesIgnoringSafeArea(.vertical)
                .padding(.trailing, -150)
            VStack(spacing: 20) {
                Spacer()
                
                // Headphone icon (SF Symbol)
                Image(systemName: "headphones")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 45, height: 45)
                    .foregroundColor(.white)
            
                // Text below the icon
                Text("Use headphone\nfor better experience")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .font(.body)
                
                Spacer()
            }
        }
    }
}

#Preview {
    OnBoard0()
}
