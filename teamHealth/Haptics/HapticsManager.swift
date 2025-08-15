//
//  HapticsManager.swift
//  test_haptics
//
//  Created by Utari Dyani Laksmi on 11/08/25.
//

//import UIKit

//struct HapticManager {
//    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
//        let generator = UINotificationFeedbackGenerator()
//        generator.prepare()
//        generator.notificationOccurred(type)
//    }
//
//    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
//        let generator = UIImpactFeedbackGenerator(style: style)
//        generator.prepare()
//        generator.impactOccurred()
//    }
//
//    static func selection() {
//        let generator = UISelectionFeedbackGenerator()
//        generator.prepare()
//        generator.selectionChanged()
//    }
//}


import UIKit
import CoreHaptics
import AVFoundation

struct HapticManager {
    private static var engine: CHHapticEngine?
    private static var supportsHaptics: Bool {
        CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }
    
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
    
    private static func createEngineIfNeeded() {
        if engine == nil {
            
        } else {
            return
        }
        
        do {
            let audioSession = AVAudioSession.sharedInstance()
            engine = try CHHapticEngine(audioSession: audioSession)
        } catch {
            print("Engine Creation Failed: \(error)")
            return
        }
        
        engine?.stoppedHandler = { reason in
            print("Engine Stopped: \(reason.rawValue)")
        }
        
        engine?.resetHandler = {
            print("Engine Reset")
            do {
                try engine?.start()
            } catch {
                print("Failed to restart engine: \(error)")
            }
        }
    }
    
    static func playAHAP(named fileName: String) {
        // Create the engine if it doesn't exist
        if !supportsHaptics {
            print("This device doesn't support Core Haptics")
            return
        }
        
        createEngineIfNeeded()
        
        guard let path = Bundle.main.path(forResource: fileName, ofType: "ahap") else {
            print("Haptic file not found: AHAP/\(fileName)")
            return
        }
        
        do {
            try engine?.start()
            try engine?.playPattern(from: URL(fileURLWithPath: path))
            print("Playing Haptic Pattern: \(fileName)")
        } catch {
            print(#function, "Error playing haptic pattern: \(error)")
        }
        
    }
}
