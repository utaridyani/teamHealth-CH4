
// OnboardingManager.swift
import SwiftUI
import Lottie

struct OnboardingManager: View {
    @State private var currentPage = 0
    let totalPages = 3
    
    @StateObject private var soundManager = SoundManager.shared
    
    @Binding var stars: [Star]
    @Binding var selectedSphereType: SphereType
    let onComplete: () -> Void  // Add completion handler
    
    @State private var showOnboardingView = false
    
    var body: some View {
        if showOnboardingView {
            OnboardingView(
                stars: $stars,
                selectedSphereType: $selectedSphereType,
                onComplete: onComplete  // Pass through the completion
            )
        } else {
            ZStack {
                TabView(selection: $currentPage) {
                    OnBoard1()
                        .tag(0)
                    OnBoard2()
                        .tag(1)
                    OnBoard3()
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .ignoresSafeArea()
                .onAppear{
                    soundManager.playTrack("Onboarding")
                }
                
                // Custom Page Control
                VStack {
                    VStack {
                        HStack {
                            Spacer()
                            SoundToggleButton(color: .white)
                                .padding(.trailing, 20)
                                .padding(.top, 50)
                        }
                        Spacer()
                    }
                    .zIndex(100)
                    
                    Spacer()
                    if currentPage < totalPages - 1 {
                        HStack(spacing: 8) {
                            ForEach(0..<totalPages, id: \.self) { index in
                                Circle()
                                    .fill(currentPage == index ? Color.white : Color.secondary.opacity(0.4))
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
                            Button(action: {
                                showOnboardingView = true
                            }) {
                                HStack() {
                                    Text("Next")
                                    Image(systemName: "chevron.right")
                                        .imageScale(.small)
                                }
                                .font(.system(size: 16, weight: .bold, design: .default))
                                .foregroundColor(.white)
                                .padding(10)
                                .padding(.horizontal, 5)
                                .background(Color.gray.opacity(0.3))
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
    @State var previewStars: [Star] = []
    @State var previewSphereType: SphereType = .dawn
    
    return OnboardingManager(
        stars: $previewStars,
        selectedSphereType: $previewSphereType,
        onComplete: {
            print("Onboarding complete from Preview")
        }
    )
}
