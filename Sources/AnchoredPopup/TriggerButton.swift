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
            .modifier(PopupPresenter(id: id, params: params, contentBuilder: contentBuilder))
    }
}

struct PopupPresenter<V>: ViewModifier where V: View {
    var id: String
    var params: PopupParameters
    @ViewBuilder var contentBuilder: () -> V

    @State private var showSheet = false

    func body(content: Content) -> some View {
        switch params.displayMode {
        case .sheet:
            content
                .onReceive(AnchoredAnimationManager.shared.statePublisher(for: id)) { animation in
                    if animation?.state == .growing {
                        showSheet = true
                    } else if animation?.state == .hidden {
                        showSheet = false
                    }
                }
                .transparentNonAnimatingFullScreenCover(isPresented: $showSheet, onDismiss: {
                    AnchoredAnimationManager.shared.changeStateForAnimation(for: id, state: .hidden)
                }) {
                    popupWithBackground
                        .environment(\.anchoredPopupDismiss) {
                            AnchoredAnimationManager.shared.changeStateForAnimation(for: id, state: .shrinking)
                        }
                }
        case .window:
            content
                .onReceive(AnchoredAnimationManager.shared.statePublisher(for: id)) { animation in
                    if animation?.state == .growing {
                        WindowManager.showInNewWindow(id: id, closeOnTapOutside: params.closeOnTapOutside, isPassthrough: params.isPassthrough) {
                            popupWithBackground
                        }
                    } else if animation?.state == .hidden {
                        WindowManager.closeWindow(id: id)
                    }
                }
        }
    }

    var popupWithBackground: some View {
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
}
