//
//  MultiTouchView.swift
//  test_haptics
//
//  Created by Utari Dyani Laksmi on 12/08/25.
//

import SwiftUI
import UIKit

/// Reports all current touches as [pointerID: CGPoint] and (optionally)
/// detects a 3‑finger left pan when `isArmed()` returns true.
struct MultiTouchView: UIViewRepresentable {
    var onChange: ([Int: CGPoint]) -> Void

    var isArmed: () -> Bool = { false }
    var onLeft: () -> Void = {}
    var onUp: () -> Void = {}

    func makeUIView(context: Context) -> TouchCaptureView {
        let v = TouchCaptureView()
        v.isMultipleTouchEnabled = true
        v.onChange = onChange

        // 3‑finger pan recognizer that rides on the same view
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

    func updateUIView(_ uiView: TouchCaptureView, context: Context) {
        context.coordinator.isArmed = isArmed
        context.coordinator.onLeft = onLeft
        context.coordinator.onUp = onUp
        uiView.onChange = onChange
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(isArmed: isArmed, onLeft: onLeft, onUp: onUp)
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var isArmed: () -> Bool
        var onLeft: () -> Void
        var onUp: () -> Void

        init(isArmed: @escaping () -> Bool, onLeft: @escaping () -> Void, onUp: @escaping () -> Void) {
            self.isArmed = isArmed
            self.onLeft = onLeft
            self.onUp = onUp
        }

        @objc func handlePan(_ g: UIPanGestureRecognizer) {
            guard g.numberOfTouches == 3 else { return }
            guard isArmed() else { return } // only honor pan after hold is armed

            if g.state == .changed || g.state == .ended {
                let t = g.translation(in: g.view)
                let v = g.velocity(in: g.view)
                
                
                let leftTriggered = (t.x <= -80) || (v.x <= -300)
                let upTriggered   = (t.y <= -80) || (v.y <= -300)

                if leftTriggered {
                    onLeft()
                    // consume once
                    g.isEnabled = false; g.isEnabled = true
                } else if upTriggered {
                    onUp()
                    // consume once
                    g.isEnabled = false; g.isEnabled = true
                }
            }
        }

        // let this coexist with anything else you add later
        func gestureRecognizer(_ g: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { true }
    }
}

final class TouchCaptureView: UIView {
    var onChange: (([Int: CGPoint]) -> Void)?

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) { report(event) }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) { report(event) }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { report(event) }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { report(event) }

    private func report(_ event: UIEvent?) {
        guard let all = event?.allTouches else { return }
        var map: [Int: CGPoint] = [:]
        for t in all {
            let id = ObjectIdentifier(t).hashValue
            let p = t.location(in: self)
            switch t.phase {
            case .began, .moved, .stationary:
                map[id] = p
            case .ended, .cancelled:
                break
            default:
                break
            }
        }
        onChange?(map)
    }
}
