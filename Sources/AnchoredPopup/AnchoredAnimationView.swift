//
//  AnchoredAnimationView.swift
//  AnchoredPopup
//
//  Created by Alisa Mylnikova on 03.07.2026.
//

import SwiftUI

struct AnchoredAnimationView<V>: View where V: View {
    var id: String
    var params: PopupParameters
    var contentBuilder: () -> V

    @State private var animatableOpacity: CGFloat = 0
    @State private var animatableScale: CGSize = .zero
    @State private var animatableOffset: CGSize = .zero

    @State private var triggerButtonFrame: CGRect = .zero
    @State private var contentSize: CGSize = .zero

    @State private var isAnimating = false

    var body: some View {
        VStack {
            contentBuilder()
                .overlay(GeometryReader { geo in
                    Color.clear.onAppear {
                        Task { @MainActor in
                            contentSize = geo.size
                            if let animation = AnchoredAnimationManager.shared.animations.first(where: { $0.id == id }) {
                                setupAndLaunchAnimation(animation)
                            }
                        }
                    }
                })
                .scaleEffect(animatableScale)
                .offset(animatableOffset)
                .offset(x: triggerButtonFrame.midX - UIScreen.main.bounds.width / 2,
                        y: triggerButtonFrame.midY - UIScreen.main.bounds.height / 2)
                .opacity(animatableOpacity)
                .ignoresSafeArea()
                .simultaneousGesture(
                    TapGesture().onEnded { gesture in
                        if params.closeOnTap {
                            // trigger hiding animation
                            AnchoredAnimationManager.shared.changeStateForAnimation(for: id, state: .shrinking)
                        }
                    }
                )
        }
        .onReceive(AnchoredAnimationManager.shared.framePublisher(for: id)) { animation in
            if let animation, triggerButtonFrame != animation.buttonFrame {
                triggerButtonFrame = animation.buttonFrame
            }
        }
        .onReceive(AnchoredAnimationManager.shared.statePublisher(for: id)) { animation in
            if let animation {
                setupAndLaunchAnimation(animation)
            }
        }
    }

    private func setupAndLaunchAnimation(_ animation: AnchoredAnimationManager.AnimationItem) {
        if contentSize == .zero || triggerButtonFrame == .zero { return }

        // ignore repeated growing requests while growing animation is in progress
        // but allow shrinking to interrupt growing
        if isAnimating && animation.state == .growing { return }

        if animation.state == .growing {
            isAnimating = true
            setHiddenState()

            if #available(iOS 17.0, *) {
                withAnimation(params.animation) {
                    setDisplayedState()
                } completion: {
                    // only update state if in growing state and not interrupted by shrinking
                    let currentState = AnchoredAnimationManager.shared.animations.first(where: { $0.id == id })?.state
                    if currentState == .growing {
                        AnchoredAnimationManager.shared.changeStateForAnimation(for: id, state: .displayed)
                    }
                    isAnimating = false
                }
            } else {
                withAnimation(params.animation) {
                    setDisplayedState()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    let currentState = AnchoredAnimationManager.shared.animations.first(where: { $0.id == id })?.state
                    if currentState == .growing {
                        AnchoredAnimationManager.shared.changeStateForAnimation(for: id, state: .displayed)
                    }
                    isAnimating = false
                }
            }
        } else if animation.state == .shrinking {
            isAnimating = true
            if #available(iOS 17.0, *) {
                withAnimation(params.animation) {
                    setHiddenState()
                } completion: {
                    AnchoredAnimationManager.shared.changeStateForAnimation(for: id, state: .hidden)
                    isAnimating = false
                }
            } else {
                withAnimation(params.animation) {
                    setHiddenState()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    AnchoredAnimationManager.shared.changeStateForAnimation(for: id, state: .hidden)
                    isAnimating = false
                }
            }
        }
    }

    private func setHiddenState() {
        animatableOffset = .zero
        animatableScale = calculateHiddenScale()
        animatableOpacity = 0
    }

    private func setDisplayedState() {
        animatableOffset = calculateDisplayedOffset()
        animatableScale = CGSize(width: 1, height: 1)
        animatableOpacity = 1
    }

    /// start with popup matching trigger's position and size
    private func calculateHiddenScale() -> CGSize {
        let tw = triggerButtonFrame.width
        let th = triggerButtonFrame.height
        let pw = contentSize.width
        let ph = contentSize.height
        return CGSize(width: tw/pw, height: th/ph)
    }

    /// starting position is center of the trigger
    private func calculateDisplayedOffset() -> CGSize {
        let cw = contentSize.width
        let ch = contentSize.height

        switch params.position {
        case .anchorRelative(let p, let keepInScreenBounds):
            let baseOffset = anchorRelativeBaseOffset(point: p, contentWidth: cw, contentHeight: ch)
            guard keepInScreenBounds else { return baseOffset }
            return clampedOffsetKeepingPopupInBounds(
                baseOffset: baseOffset,
                contentWidth: cw,
                contentHeight: ch,
                bounds: safeAreaBounds()
            )

        case .auto:
            let bounds = safeAreaBounds()
            let autoPoint = autoAnchorPoint(contentWidth: cw, contentHeight: ch, bounds: bounds)
            let baseOffset = anchorRelativeBaseOffset(point: autoPoint, contentWidth: cw, contentHeight: ch)
            return clampedOffsetKeepingPopupInBounds(
                baseOffset: baseOffset,
                contentWidth: cw,
                contentHeight: ch,
                bounds: bounds
            )

        case .screenRelative(let p):
            let tx = triggerButtonFrame.midX
            let ty = triggerButtonFrame.midY
            let sw = UIScreen.main.bounds.width
            let sh = UIScreen.main.bounds.height

            // normalization: (0, 1) -> (1, -1)
            let px = -2 * p.x + 1
            let py = -2 * p.y + 1

            // the content view center is currently same as anchor view
            // -tx: put middle of popup into (0,0)
            // sw * p.x: put middle of popup into required unit point of screen
            // cw/2 * px: align required unit point of popup with the screen
            return CGSize(width: -tx + sw * p.x + cw/2 * px, height: -ty + sh * p.y + ch/2 * py)

        case .absolute(let point, let position):
            let tx = triggerButtonFrame.midX
            let ty = triggerButtonFrame.midY

            // normalization: (0, 1) -> (1, -1)
            let px = -2 * point.x + 1
            let py = -2 * point.y + 1

            // the content view center is currently same as anchor view
            // -tx: put middle of popup into (0,0)
            // position.x: put middle of popup into the exact screen position
            // cw/2 * px: align the specified unit point of popup with that position
            return CGSize(width: -tx + position.x + cw/2 * px, height: -ty + position.y + ch/2 * py)
        }
    }

    private func anchorRelativeBaseOffset(
        point p: UnitPoint,
        contentWidth cw: CGFloat,
        contentHeight ch: CGFloat
    ) -> CGSize {
        let tw = triggerButtonFrame.width
        let th = triggerButtonFrame.height

        // difference between centers
        let w = cw/2 - tw/2
        let h = ch/2 - th/2

        // normalization: (0, 1) -> (1, -1)
        let px = -2 * p.x + 1
        let py = -2 * p.y + 1

        // the content view center is currently same as anchor view
        // +/- the difference between centers
        return CGSize(width: w * px, height: h * py)
    }

    private func clampedOffsetKeepingPopupInBounds(
        baseOffset: CGSize,
        contentWidth cw: CGFloat,
        contentHeight ch: CGFloat,
        bounds: CGRect
    ) -> CGSize {
        let triggerCenter = CGPoint(x: triggerButtonFrame.midX, y: triggerButtonFrame.midY)
        let desiredCenter = CGPoint(x: triggerCenter.x + baseOffset.width, y: triggerCenter.y + baseOffset.height)

        let halfW = cw / 2
        let halfH = ch / 2

        // If popup is larger than bounds, keep as much visible as possible by clamping using bounds half-size
        let clampedHalfW = min(halfW, bounds.width / 2)
        let clampedHalfH = min(halfH, bounds.height / 2)

        let minCenterX = bounds.minX + clampedHalfW
        let maxCenterX = bounds.maxX - clampedHalfW
        let minCenterY = bounds.minY + clampedHalfH
        let maxCenterY = bounds.maxY - clampedHalfH

        let clampedCenter = CGPoint(
            x: min(max(desiredCenter.x, minCenterX), maxCenterX),
            y: min(max(desiredCenter.y, minCenterY), maxCenterY)
        )

        return CGSize(width: clampedCenter.x - triggerCenter.x, height: clampedCenter.y - triggerCenter.y)
    }

    private func autoAnchorPoint(contentWidth cw: CGFloat, contentHeight ch: CGFloat, bounds: CGRect) -> UnitPoint {
        let candidates: [UnitPoint] = [.topLeading, .topTrailing, .bottomLeading, .bottomTrailing]
        let triggerCenter = CGPoint(x: triggerButtonFrame.midX, y: triggerButtonFrame.midY)

        // Stay on the same side of the screen as the anchor
        let preferredX: CGFloat = triggerCenter.x < bounds.midX ? 0 : 1
        let preferredY: CGFloat = triggerCenter.y < bounds.midY ? 0 : 1

        func overflowScore(for point: UnitPoint) -> CGFloat {
            let baseOffset = anchorRelativeBaseOffset(point: point, contentWidth: cw, contentHeight: ch)
            let center = CGPoint(x: triggerCenter.x + baseOffset.width, y: triggerCenter.y + baseOffset.height)
            let frame = CGRect(x: center.x - cw/2, y: center.y - ch/2, width: cw, height: ch)

            let overflowLeft = max(bounds.minX - frame.minX, 0)
            let overflowRight = max(frame.maxX - bounds.maxX, 0)
            let overflowTop = max(bounds.minY - frame.minY, 0)
            let overflowBottom = max(frame.maxY - bounds.maxY, 0)

            // Minimize how much of the popup goes outside bounds
            let overflow = overflowLeft + overflowRight + overflowTop + overflowBottom

            // Choose the closest corner for the anchor
            let tieBreaker = abs(point.x - preferredX) * 0.001 + abs(point.y - preferredY) * 0.001
            return overflow + tieBreaker
        }

        return candidates.min(by: { overflowScore(for: $0) < overflowScore(for: $1) }) ?? .bottomLeading
    }

    private func safeAreaBounds() -> CGRect {
        if let window = WindowManager.shared.windows[id] {
            return window.bounds.inset(by: window.safeAreaInsets)
        }

        return UIScreen.main.bounds
    }
}
