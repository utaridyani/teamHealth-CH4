//
//  teamHealthApp.swift
//  teamHealth
//
//  Created by Utari Dyani Laksmi on 14/08/25.
//

import SwiftUI
import SwiftData

@main
struct teamHealthApp: App {
    @StateObject var hapticData = HapticData()
    @StateObject var selectedHaptic = SelectedHaptic()
    @State private var showOnboarding = true
    @State private var onboardingStars: [Star] = []
    @State private var selectedSphereType: SphereType = .dawn
    
    var body: some Scene {
        WindowGroup {
            if showOnboarding {
                OnboardingView(
                    stars: $onboardingStars,
                    selectedSphereType: $selectedSphereType
                ) {
                    showOnboarding = false
                }
            } else {
                MainMenuView(
                    inheritedStars: onboardingStars,
                    initialSphereType: selectedSphereType
                )
                .environmentObject(selectedHaptic)
                .environmentObject(hapticData)
            }
        }
    }
}
