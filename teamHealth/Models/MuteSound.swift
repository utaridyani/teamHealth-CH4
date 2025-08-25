//
//  MuteSound.swift
//  test_haptics
//
//  Created by Utari Dyani Laksmi on 24/08/25.
//

// ADD THIS OK
import SwiftUI

final class MuteStore: ObservableObject {
    @Published var isMuted: Bool {
        didSet {
            SoundManager.shared.isSoundEnabled = !isMuted
            if !isMuted {
                SoundManager.shared.playTrack("Onboarding", immediate: true)
            }
        }
    }

    init() {
        let enabled = SoundManager.shared.isSoundEnabled
        self.isMuted = !enabled

        // start right away
        if enabled {
            SoundManager.shared.playTrack("Onboarding", immediate: true)
        }
    }
}
