//
//  TextFadeIn.swift
//  teamHealth
//
//  Created by Utari Dyani Laksmi on 25/08/25.
//

import SwiftUI

struct FadeInOnAppear: ViewModifier {
    let delay: Double
    let duration: Double
    @State private var visible = false

    func body(content: Content) -> some View {
        content
            .opacity(visible ? 1 : 0)
            .animation(.easeOut(duration: duration).delay(delay), value: visible)
            .onAppear { visible = true }
            .onDisappear { visible = false } 
    }
}

extension View {
    func fadeInOnAppear(delay: Double = 0, duration: Double = 0.35) -> some View {
        self.modifier(FadeInOnAppear(delay: delay, duration: duration))
    }
}
