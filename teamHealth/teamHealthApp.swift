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

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(hapticData)
        }
    }
}
