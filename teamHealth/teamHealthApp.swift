//
//  teamHealthApp.swift
//  teamHealth
//
//  Created by Utari Dyani Laksmi on 14/08/25.
//


import SwiftUI

struct CombinedView: View {
    // State to manage the transition between onboarding and main menu
    @State private var showOnboarding = true
    
    // Shared state for the star animation and selected sphere
    @State private var stars: [Star] = []
    @State private var selectedSphereType: SphereType = .dawn
    
    var body: some View {
        ZStack {
            if showOnboarding {
                OnboardingView(
                    stars: $stars,
                    selectedSphereType: $selectedSphereType,
                    onComplete: {
                        // This closure is called when the onboarding animation finishes
                        withAnimation(.easeInOut(duration: 1.0)) {
                            showOnboarding = false
                        }
                    }
                )
            } else {
                MainMenuView(
                    inheritedStars: stars,
                    initialSphereType: selectedSphereType
                )
                // A subtle transition to fade in the main menu
                .transition(.opacity)
            }
        }
    }
}

#Preview {
    CombinedView()
        .environmentObject(SelectedHaptic())
}
