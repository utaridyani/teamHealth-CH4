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

    @State private var onboardingStars: [Star] = []
    @State private var selectedSphereType: SphereType = .dawn
    
    @StateObject var mute = MuteStore()

    // guided tutorial
    @AppStorage("didFinishOnboarding") private var didFinishOnboarding = false
    @AppStorage("didFinishTutorial")   private var didFinishTutorial   = false

    var body: some Scene {
        WindowGroup {
            if !didFinishOnboarding {
                OnboardingManager(
                    stars: $onboardingStars,
                    selectedSphereType: $selectedSphereType,
                    onComplete: { didFinishOnboarding = true }
                )
            } else if !didFinishTutorial {
                MainTutorialView(
                    onComplete: { didFinishTutorial = true }
                )
                    .environmentObject(mute)
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
