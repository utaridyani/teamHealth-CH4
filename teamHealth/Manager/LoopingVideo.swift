//
//  LoopingVideo.swift
//  buzzle
//
//  Created by Felly on 18/08/25.
//

import SwiftUI
import AVFoundation

// Keeps the video playing & looping (no public play/pause)
final class LoopingPlayer: ObservableObject {
    let player = AVQueuePlayer()
    private var looper: AVPlayerLooper?

    init(resource: String, ext: String = "mp4", muted: Bool = true) {
        guard let url = Bundle.main.url(forResource: resource, withExtension: ext) else {
            print("Missing \(resource).\(ext)")
            return
        }
        let item = AVPlayerItem(url: url)
        looper = AVPlayerLooper(player: player, templateItem: item) // seamless loop
        player.isMuted = muted
        player.play()
    }
}

final class PlayerHostView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
}

struct PlayerLayerRepresentable: UIViewRepresentable {
    let player: AVPlayer
    var gravity: AVLayerVideoGravity = .resizeAspect

    func makeUIView(context: Context) -> PlayerHostView {
        let v = PlayerHostView()
        v.backgroundColor = .clear
        v.playerLayer.player = player
        v.playerLayer.videoGravity = gravity
        return v
    }
    func updateUIView(_ uiView: PlayerHostView, context: Context) {
        uiView.playerLayer.player = player
        uiView.playerLayer.videoGravity = gravity
    }
}

struct LoopingVideo: View {
    @StateObject private var vm: LoopingPlayer
    var gravity: AVLayerVideoGravity

    init(resource: String, ext: String = "mp4", muted: Bool = true,
         gravity: AVLayerVideoGravity = .resizeAspect) {
        _vm = StateObject(wrappedValue: LoopingPlayer(resource: resource, ext: ext, muted: muted))
        self.gravity = gravity
    }

    var body: some View {
        PlayerLayerRepresentable(player: vm.player, gravity: gravity)
            .allowsHitTesting(false)   // video doesn’t receive touches
            .accessibilityHidden(true) // not focusable/announced
    }
}

