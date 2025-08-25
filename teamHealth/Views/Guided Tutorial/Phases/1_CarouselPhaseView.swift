//
//  CarouselPhaseView.swift
//  test_haptics
//
//  Created by Utari Dyani Laksmi on 24/08/25.
//
import SwiftUI


// MARK: Subview - Carousel Phase
struct CarouselPhaseView: View {
    @Binding var stars: [Star]
    let themes: [MainTutorialView.Theme]
    let red: Color
    @Binding var index: Int
    @Binding var advance: Bool
    var onFinishedSlides: () -> Void

    @State private var settlePhase = false
    @State private var sideFade: Double = 1.0
    @State private var centerScale: CGFloat = 1.0
    @State private var glowIntensity: Double = AnimationConstants.sphereGlowIntensity

    var body: some View {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height

        let centerWidth = screenWidth / 2
        let centerHeight = screenHeight / 2
        let sideWidth = screenWidth / 4
        let sideHeight = screenHeight / 3

        let leftX  : CGFloat = -screenWidth * 0.5
        let centerX: CGFloat = 0
        let rightX : CGFloat =  screenWidth * 0.5
        let offLeftX: CGFloat = -screenWidth * 0.9
        let newRightStartX: CGFloat =  screenWidth * 0.9

        let count   = themes.count
        let current = themes[index]
        let prev    = themes[(index - 1 + count) % count]
        let nextDisp     = themes[(index + 1) % count]
        let nextNextDisp = themes[(index + 2) % count]

        let hasMore = index < count - 1

        ZStack {
            AmbientDecor(stars: $stars)
            
            VStack(spacing: 0) {
                Text(settlePhase ? "Let's get started with the\nTwilight Bubble" : "There are three types of bubbles\nthat represent different vibrations")
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(
                      LinearGradient(
                        colors: [Color.white, Color.white.opacity(0.5)],
                        startPoint: .top,
                        endPoint: .bottom
                      )
                    )


                ZStack {
                    // LEFT
                    RescaledSphere(
                        sphereType: sphereType(for: prev),
                        isActive: false,
                        targetWidth: sideWidth,
                        targetHeight: sideHeight
                    )
                    .compositingGroup()
                    .blur(radius: settlePhase ? 8 : 8)
                    .offset(x: advance ? offLeftX : leftX)
                    .opacity(settlePhase ? sideFade : 0.9)
                    .zIndex(0.1)

                    // CENTER
                    Group {
                        if settlePhase {
                            ZStack{
                                RescaledSphere(
                                    sphereType: .twilight,
                                    isActive: true,
                                    targetWidth: centerWidth,
                                    targetHeight: centerHeight,
                                    scale: $centerScale,
                                    glowIntensity: $glowIntensity
                                )
                                .offset(x: centerX)
                                .zIndex(0.4)
                                RescaledSphere(
                                    sphereType: .twilight,
                                    isActive: true,
                                    targetWidth: centerWidth,
                                    targetHeight: centerHeight,
                                    scale: $centerScale,
                                    glowIntensity: $glowIntensity
                                )
                                .offset(x: centerX)
                                .zIndex(0.4)
                            }

                        } else {
                            ZStack {
                                RescaledSphere(
                                    sphereType: sphereType(for: current),
                                    isActive: true,
                                    targetWidth: advance ? sideWidth : centerWidth,
                                    targetHeight: advance ? sideHeight : centerHeight
                                )
                                .compositingGroup()
                                .blur(radius: advance ? 10 : 0)
                                .opacity(advance ? 0.9 : 1)
                                .offset(x: advance ? leftX : centerX)
                                .zIndex(0.3)
                                RescaledSphere(
                                    sphereType: sphereType(for: current),
                                    isActive: true,
                                    targetWidth: advance ? sideWidth : centerWidth,
                                    targetHeight: advance ? sideHeight : centerHeight
                                )
                                .compositingGroup()
                                .blur(radius: advance ? 10 : 0)
                                .opacity(advance ? 0.9 : 1)
                                .offset(x: advance ? leftX : centerX)
                                .zIndex(0.3)
                            }

                        }
                    }

                    // RIGHT
                    RescaledSphere(
                        sphereType: sphereType(for: nextDisp),
                        isActive: false,
                        targetWidth: (settlePhase ? sideWidth : (advance ? centerWidth : sideWidth)),
                        targetHeight: (settlePhase ? sideHeight : (advance ? centerHeight : sideHeight))
                    )
                    .compositingGroup()
                    .blur(radius: advance ? 0 : 10)
                    .offset(x: (settlePhase ? rightX : (advance ? centerX : rightX)))
                    .opacity(settlePhase ? sideFade : 1.0)
                    .zIndex(0.5)

                    // NEXT-NEXT (peek)
                    if hasMore && !settlePhase {
                        RescaledSphere(
                            sphereType: sphereType(for: nextNextDisp),
                            isActive: false,
                            targetWidth: sideWidth,
                            targetHeight: sideHeight
                        )
                        .compositingGroup()
                        .blur(radius: 10)
                        .offset(x: advance ? rightX : newRightStartX)
                        .opacity(0.95)
                        .zIndex(0.6)
                    }
                }
                .padding(.top, -50)

                let titleName = settlePhase
                    ? "Twilight"
                    : ((advance && hasMore) ? nextDisp.name : current.name)

                Text(titleName)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(
                      LinearGradient(
                        colors: [Color.white, Color.white.opacity(0.5)],
                        startPoint: .top,
                        endPoint: .bottom
                      )
                    )
                    .padding(.top, -60)
            }
            .ignoresSafeArea()
            .navigationBarBackButtonHidden()
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    play()
                }
            }
            .animation(.spring(response: 1.0, dampingFraction: 0.82, blendDuration: 0.8),
                       value: advance)
            .animation(.easeInOut(duration: 2), value: advance)
            .onChange(of: advance) { _, newValue in
                guard newValue == true else { return }
                let slideDuration = 1.0
                DispatchQueue.main.asyncAfter(deadline: .now() + slideDuration) {
                    var tx = Transaction(); tx.disablesAnimations = true
                    withTransaction(tx) {
                        if index + 1 < themes.count {
                            index += 1
                            advance = false
                        } else {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                advance = false
                            }
                        }
                    }

                    if index >= themes.count - 1 {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            settlePhase = true
                            centerScale = 0.5
                            sideFade = 1.0
                            withAnimation(.easeInOut(duration: 2.0)) {
                                centerScale = 1.0
                                sideFade = 0.0
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                onFinishedSlides()
                            }
                        }
                    } else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            play()
                        }
                    }
                }
            }
        }
    }

    private func play() {
        if !advance { advance = true }
    }

    private func sphereType(for theme: MainTutorialView.Theme) -> SphereType {
        switch theme.name.lowercased() {
        case "dawn":     return .dawn
        case "twilight": return .twilight
        case "reverie":  return .reverie
        default:         return .dawn
        }
    }
}


struct RescaledSphere: View {
    let sphereType: SphereType
    let isActive: Bool
    let targetWidth: CGFloat
    let targetHeight: CGFloat
    @Binding var scale: CGFloat
    @Binding var glowIntensity: Double

    var body: some View {
        let base: CGFloat = 220
        let s = min(targetWidth / base, targetHeight / base)

        GlowingSphereView(
            sphereType: sphereType,
            isActive: isActive,
            scale: $scale,
            glowIntensity: $glowIntensity
        )
        .frame(width: base, height: base)
        .scaleEffect(s, anchor: .center)
        .frame(width: targetWidth, height: targetHeight, alignment: .center)
    }
}

// Convenience initializers for constant scale/glow, so you can use it like a plain view.
extension RescaledSphere {
    init(sphereType: SphereType, isActive: Bool, targetWidth: CGFloat, targetHeight: CGFloat) {
        self.sphereType = sphereType
        self.isActive = isActive
        self.targetWidth = targetWidth
        self.targetHeight = targetHeight
        _scale = .constant(1.0)
        _glowIntensity = .constant(1.0)
    }
}
