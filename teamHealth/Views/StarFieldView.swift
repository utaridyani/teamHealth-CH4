//
//  StarFieldView.swift
//  teamHealth
//
//  Created by Utari Dyani Laksmi on 17/08/25.
//

import SwiftUI

struct StarField: View {
    let starCount: Int
    @State private var stars: [Star] = []

    struct Star: Identifiable {
        let id = UUID()
        let pos: CGPoint
        let size: CGFloat
        let baseOpacity: Double
        let twinkleSpeed: Double
        let phase: Double
    }

    init(starCount: Int = 140) { self.starCount = starCount }

    var body: some View {
        GeometryReader { geo in
            // Use TimelineView for twinkle
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                ZStack {
                    ForEach(stars) { s in
                        Circle()
                            .fill(.white)
                            .frame(width: s.size, height: s.size)
                            .position(s.pos)
                            .opacity(opacity(for: s, time: t))
                            .blur(radius: s.size > 1.2 ? 0.6 : 0)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .onAppear {
                    if stars.isEmpty {
                        let size = geo.size == .zero
                            ? CGSize(width: UIScreen.main.bounds.width,
                                     height: UIScreen.main.bounds.height)
                            : geo.size
                        stars = makeStars(in: size)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // <- ensure it fills
        .ignoresSafeArea()
        .allowsHitTesting(false) // don’t block your circles/gestures
    }

    private func makeStars(in size: CGSize) -> [Star] {
        (0..<starCount).map { _ in
            let pos = CGPoint(x: .random(in: 0...size.width),
                              y: .random(in: 0...size.height))
            let s = CGFloat.random(in: 0.8...2.2)
            let base = Double.random(in: 0.35...0.85)
            let speed = Double.random(in: 0.6...1.8)
            let phase = Double.random(in: 0...(2 * .pi))
            return Star(pos: pos, size: s, baseOpacity: base, twinkleSpeed: speed, phase: phase)
        }
    }

    private func opacity(for s: Star, time t: TimeInterval) -> Double {
        // base + (0..1)*amplitude, clamped 0..1
        let amp = 0.15 + (s.size - 0.8) * 0.1  // slightly bigger stars twinkle a bit more
        let v = s.baseOpacity + amp * (sin(t * s.twinkleSpeed + s.phase) * 0.5 + 0.5)
        return max(0.0, min(1.0, v))
    }
}
