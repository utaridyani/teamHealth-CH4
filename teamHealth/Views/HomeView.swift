//
//  HomeView.swift
//  teamHealth
//
//  Created by Utari Dyani Laksmi on 14/08/25.
//


// no longer used
import SwiftUI


struct HomeView: View {
    @StateObject var hapticData = HapticData()
    
    var body: some View {
        NavigationStack{
            VStack {
                NavigationLink(destination: PickHapticsView().environmentObject(hapticData)) {
                    Text("Start Session")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .navigationBarBackButtonHidden()
        }

    }
}

#Preview {
    HomeView()
}
