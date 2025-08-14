//
//  ThreeGestures.swift
//  test_haptics
//
//  Created by Utari Dyani Laksmi on 13/08/25.
//


// not used anymore -> moved to multi touch view


import SwiftUI
import UIKit

struct ThreeFingerPanLeft: UIViewRepresentable {
    var isArmed: () -> Bool
    var onLeft: () -> Void

    func makeUIView(context: Context) -> UIView {
        let v = UIView()
        v.isUserInteractionEnabled = true
        v.isMultipleTouchEnabled = true

        let pan = UIPanGestureRecognizer(target: context.coordinator,
                                         action: #selector(Coordinator.handlePan(_:)))
        pan.minimumNumberOfTouches = 3
        pan.maximumNumberOfTouches = 3
        pan.cancelsTouchesInView = false
        pan.requiresExclusiveTouchType = false
        pan.delegate = context.coordinator
        v.addGestureRecognizer(pan)
        return v
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.isArmed = isArmed
        context.coordinator.onLeft = onLeft
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isArmed: isArmed, onLeft: onLeft)
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var isArmed: () -> Bool
        var onLeft: () -> Void

        init(isArmed: @escaping () -> Bool, onLeft: @escaping () -> Void) {
            self.isArmed = isArmed
            self.onLeft = onLeft
        }

        @objc func handlePan(_ g: UIPanGestureRecognizer) {
            guard g.numberOfTouches == 3 else { return }

            // Only respond if hold has finished
            guard isArmed() else { return }

            if g.state == .changed || g.state == .ended {
                let t = g.translation(in: g.view)
                let v = g.velocity(in: g.view)
                if t.x <= -80 || v.x <= -300 {
                    onLeft()
                    g.isEnabled = false
                    g.isEnabled = true
                }
            }
        }

        func gestureRecognizer(_ g: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { true }
    }
}
