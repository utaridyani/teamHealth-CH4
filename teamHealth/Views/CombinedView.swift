//
//  CombinedView.swift
//  teamHealth
//
//  Created by Zap on 23/08/25.
//

import SwiftUI
import SwiftData

@main
struct teamHealthApp: App {
    @StateObject var hapticData = HapticData()
    @StateObject var selectedHaptic = SelectedHaptic()
    
    var body: some Scene {
        WindowGroup {
            // The CombinedView now manages the onboarding state and the transition to the main menu.
            CombinedView()
                .environmentObject(selectedHaptic)
                .environmentObject(hapticData) // Pass this if CombinedView's children need it
        }
    }
}
