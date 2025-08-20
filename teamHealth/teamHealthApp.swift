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
    
    var body: some Scene {
        WindowGroup {
            MainMenuView()
                .environmentObject(selectedHaptic)
                .environmentObject(hapticData)
        }
    }
}
