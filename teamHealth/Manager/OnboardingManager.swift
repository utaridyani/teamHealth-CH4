//
//  OnboardingView.swift
//  buzzle
//
//  Created by Henokh Abhinaya Tjahjadi on 19/08/25.
//

import SwiftUI
import Lottie

struct OnboardingManager: View {
    @State private var currentPage = 0
    let totalPages = 3
    
    @State private var stars: [Star] = []
    @State private var selectedSphereType: SphereType = .dawn
    
    var body: some View {
        NavigationStack {
            ZStack {
                TabView(selection: $currentPage) {
                    OnBoard1()
                        .tag(0)
                    OnBoard2()
                        .tag(1)
                    OnBoard3()
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never)) // hide default dots
                .ignoresSafeArea()
                
                // Custom Page Control
                VStack {
                    Spacer()
                    if currentPage < totalPages - 1 {
                        HStack(spacing: 8) {
                            ForEach(0..<totalPages, id: \.self) { index in
                                Circle()
                                    .fill(currentPage == index ? Color.whiteu : Color.secondary.opacity(0.4))
                                    .frame(width: currentPage == index ? 12 : 8,
                                           height: currentPage == index ? 12 : 8)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                                    .onTapGesture {
                                        currentPage = index
                                    }
                            }
                        }
                        .padding(.bottom, 60)
                        .transition(.opacity)
                    }
                    
                    if currentPage == totalPages - 1 {
                        HStack {
                            Spacer()
                            NavigationLink(
                                destination: OnboardingView(
                                    stars: $stars,
                                    selectedSphereType: $selectedSphereType
                                ){
                                    print("Onboarding complete from Manager")
                                }) {
                                HStack(spacing: 6) {
                                    Text("Next")
                                    Image(systemName: "chevron.right")
                                        .imageScale(.small)
                                }
                                .font(.system(size: 16, weight: .bold, design: .default))
                                .foregroundColor(.whiteu)
                                .padding(10)
                                .padding(.horizontal, 5)
                                .background(Color.darkgrey)
                                .cornerRadius(18)
                                .shadow(radius: 4)
                            }
                            .padding(.trailing, 40)
                            .padding(.bottom, 45)
                            .transition(.opacity.combined(with: .move(edge: .trailing)))
                            .animation(.easeInOut, value: currentPage)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationView{
        OnboardingManager()
    }
    
}
