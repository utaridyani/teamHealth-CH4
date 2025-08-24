//
//  SoundManager.swift
//  teamHealth
//
//  Created by Zap on 23/08/25.
//

import SwiftUI
import AVFoundation

class SoundManager: ObservableObject {
    static let shared = SoundManager()
    
    @Published var isSoundEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(isSoundEnabled, forKey: "soundEnabled")
            if isSoundEnabled {
                resumeCurrentTrack()
            } else {
                pauseAllTracks()
            }
        }
    }
    
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private var currentTrack: String = ""
    private var fadeTimer: Timer?
    private let fadeDuration: TimeInterval = 1.0
    private let fadeSteps: Int = 30
    
    init() {
        // Load saved preference
        isSoundEnabled = UserDefaults.standard.object(forKey: "soundEnabled") as? Bool ?? true
        
        // Setup audio session
        setupAudioSession()
        
        // Preload all audio files
        preloadAudioFiles()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func preloadAudioFiles() {
        let audioFiles = [
            "Onboarding": "Onboarding",
            "Dawn": "Dawn",
            "Twilight": "Twilight",
            "Reverie": "Reverie"
        ]
        
        for (key, filename) in audioFiles {
            if let url = Bundle.main.url(forResource: filename, withExtension: "m4a") {
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.numberOfLoops = -1 // Loop indefinitely
                    player.volume = 0.0
                    player.prepareToPlay()
                    audioPlayers[key] = player
                } catch {
                    print("Failed to load audio file \(filename): \(error)")
                }
            }
        }
    }
    
    // MARK: - Public Methods
    
    func playTrack(_ trackName: String, immediate: Bool = false) {
        guard isSoundEnabled else { return }
        
        if trackName == currentTrack {
            return // Already playing this track
        }
        
        if immediate {
            // Stop current track immediately
            stopCurrentTrack()
            startTrack(trackName)
        } else {
            // Smooth crossfade transition
            crossfadeToTrack(trackName)
        }
    }
    
    func toggleSound() {
        isSoundEnabled.toggle()
    }
    
    // MARK: - Private Methods
    
    private func startTrack(_ trackName: String) {
        guard let player = audioPlayers[trackName] else { return }
        
        currentTrack = trackName
        player.volume = 0.0
        player.play()
        
        // Fade in
        fadeVolume(for: player, from: 0.0, to: 0.7, duration: fadeDuration)
    }
    
    private func stopCurrentTrack() {
        guard !currentTrack.isEmpty,
              let player = audioPlayers[currentTrack] else { return }
        
        player.stop()
        player.currentTime = 0
        player.volume = 0.0
        currentTrack = ""
    }
    
    private func pauseAllTracks() {
        fadeTimer?.invalidate()
        for player in audioPlayers.values {
            player.pause()
        }
    }
    
    private func resumeCurrentTrack() {
        guard !currentTrack.isEmpty,
              let player = audioPlayers[currentTrack] else { return }
        
        player.play()
        fadeVolume(for: player, from: player.volume, to: 0.7, duration: fadeDuration / 2)
    }
    
    private func crossfadeToTrack(_ newTrack: String) {
        guard let newPlayer = audioPlayers[newTrack] else { return }
        
        // Cancel any existing fade
        fadeTimer?.invalidate()
        
        // Start the new track at 0 volume
        newPlayer.volume = 0.0
        newPlayer.play()
        
        // Fade out old track (if exists) and fade in new track simultaneously
        if !currentTrack.isEmpty, let oldPlayer = audioPlayers[currentTrack] {
            let fadeOutSteps = fadeSteps
            let fadeInSteps = fadeSteps
            var currentStep = 0
            
            let initialOldVolume = oldPlayer.volume
            let targetNewVolume: Float = 0.7
            
            fadeTimer = Timer.scheduledTimer(withTimeInterval: fadeDuration / Double(fadeSteps), repeats: true) { timer in
                currentStep += 1
                
                // Calculate progress
                let progress = Float(currentStep) / Float(fadeOutSteps)
                
                // Fade out old track
                oldPlayer.volume = initialOldVolume * (1.0 - progress)
                
                // Fade in new track
                newPlayer.volume = targetNewVolume * progress
                
                // Complete transition
                if currentStep >= fadeOutSteps {
                    timer.invalidate()
                    oldPlayer.stop()
                    oldPlayer.currentTime = 0
                    oldPlayer.volume = 0.0
                    self.currentTrack = newTrack
                }
            }
        } else {
            // No current track, just fade in the new one
            currentTrack = newTrack
            fadeVolume(for: newPlayer, from: 0.0, to: 0.7, duration: fadeDuration)
        }
    }
    
    private func fadeVolume(for player: AVAudioPlayer, from startVolume: Float, to endVolume: Float, duration: TimeInterval) {
        player.volume = startVolume
        
        let volumeDelta = endVolume - startVolume
        var currentStep = 0
        let totalSteps = fadeSteps
        
        fadeTimer?.invalidate()
        fadeTimer = Timer.scheduledTimer(withTimeInterval: duration / Double(totalSteps), repeats: true) { timer in
            currentStep += 1
            let progress = Float(currentStep) / Float(totalSteps)
            player.volume = startVolume + (volumeDelta * progress)
            
            if currentStep >= totalSteps {
                timer.invalidate()
            }
        }
    }
    
    // MARK: - Sphere Type Helper
    func trackName(for sphereType: SphereType) -> String {
        switch sphereType {
        case .dawn:
            return "Dawn"
        case .twilight:
            return "Twilight"
        case .reverie:
            return "Reverie"
        }
    }
}

// MARK: - Sound Toggle Button View
struct SoundToggleButton: View {
    @ObservedObject var soundManager = SoundManager.shared
    let color: Color
    
    var body: some View {
        Button(action: {
            soundManager.toggleSound()
            HapticManager.selection()
        }) {
            ZStack {
                // Background circle with sphere color
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                color.opacity(0.3),
                                color.opacity(0.5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                
                Circle()
                    .stroke(color.opacity(0.6), lineWidth: 1.5)
                    .frame(width: 44, height: 44)
                
                // Sound icon
                Image(systemName: soundManager.isSoundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .shadow(color: color.opacity(0.5), radius: 2)
            }
        }
        .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
        .scaleEffect(soundManager.isSoundEnabled ? 1.0 : 0.9)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: soundManager.isSoundEnabled)
    }
}
