//
//  TriggerButton.swift
//  AnchoredPopup
//
//  Created by Alisa Mylnikova on 03.07.2026.
//

import SwiftUI

struct TriggerButton<V>: ViewModifier where V: View {
    var id: String
    var params: PopupParameters
    @ViewBuilder var contentBuilder: () -> V

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geo in
                    Color.clear
                        .preference(key: ButtonFramePreferenceKey.self, value: ButtonFrameInfo(id: id, frame: geo.frame(in: .global)))
                }
            }
            .onPreferenceChange(ButtonFramePreferenceKey.self) { value in
                Task { @MainActor in
                    if id == value.id {
                        AnchoredAnimationManager.shared.updateFrame(for: value.id, frame: value.frame)
                    }
                }
            }
            .simultaneousGesture(
                params.openOnTap ? TapGesture().onEnded { _ in
                    // trigger displaying animation only if popup is hidden
                    let currentState = AnchoredAnimationManager.shared.animations.first(where: { $0.id == id })?.state
                    if currentState == .hidden || currentState == nil {
                        hideKeyboard()
                        AnchoredAnimationManager.shared.changeStateForAnimation(for: id, state: .growing)
                    }
                } : nil
            )
            .onReceive(AnchoredAnimationManager.shared.statePublisher(for: id)) { animation in
                if animation?.state == .growing {
                    WindowManager.openNewWindow(id: id, closeOnTapOutside: params.closeOnTapOutside, isPassthrough: params.isPassthrough) {
                        ZStack {
                            AnimatedBackgroundView(id: id, background: params.background)
                                .simultaneousGesture(
                                    TapGesture().onEnded {
                                        if params.closeOnTapOutside {
                                            // trigger hiding animation
                                            AnchoredAnimationManager.shared.changeStateForAnimation(for: id, state: .shrinking)
                                        }
                                    }
                                )
                            AnchoredAnimationView(id: id, params: params, contentBuilder: contentBuilder)
                        }
                    }
                } else if animation?.state == .hidden {
                    WindowManager.closeWindow(id: id)
                }
            }
    }
}
