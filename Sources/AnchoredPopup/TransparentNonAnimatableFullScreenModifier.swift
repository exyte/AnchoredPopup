//
//  TransparentNonAnimatableFullScreenModifier.swift
//  PopupView
//
//  Created by Alisa Mylnikova on 29.05.2026.
//

import SwiftUI

#if os(iOS)

extension View {
    func transparentNonAnimatingFullScreenCover<Content: View>(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil,
        content: @escaping () -> Content) -> some View {
            modifier(TransparentNonAnimatableFullScreenModifier(isPresented: isPresented, onDismiss: onDismiss, fullScreenContent: content))
        }
}

/// Presents `fullScreenContent` imperatively via UIKit (instead of `.fullScreenCover`) so we own the
/// resulting `UIHostingController` and can set `safeAreaRegions = []` on it directly.
/// `.fullScreenCover` creates its own internal hosting controller we have no reference to, which leaves
/// its safe area resolution to settle asynchronously and can cause a visible, non-animated snap partway
/// through a popup's grow animation.
private struct TransparentNonAnimatableFullScreenModifier<FullScreenContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let onDismiss: (() -> Void)?
    let fullScreenContent: () -> (FullScreenContent)

    @State private var presenter: UIViewController?
    @State private var presentedController: UIViewController?
    @State private var updateContent: ((FullScreenContent) -> Void)?

    func body(content: Content) -> some View {
        if presentedController != nil {
            let _ = updateContent?(fullScreenContent())
        }

        return content
            .background(PresenterAccessor { presenter = $0 })
            .onChange(of: isPresented) {
                if isPresented {
                    present()
                } else {
                    dismissPresented()
                }
            }
    }

    private func makeRoot(_ content: FullScreenContent) -> some View {
        ZStack {
            content
        }
        .background(FullScreenCoverBackgroundRemovalView())
        .onDisappear {
            if !UIView.areAnimationsEnabled {
                UIView.setAnimationsEnabled(true)
            }
        }
    }

    private func present() {
        guard let presenter, presentedController == nil else { return }
        UIView.setAnimationsEnabled(false)

        let controller = UIHostingController(rootView: makeRoot(fullScreenContent()))
        controller.safeAreaRegions = []
        controller.view.backgroundColor = .clear
        controller.modalPresentationStyle = .overFullScreen
        presentedController = controller
        updateContent = { [weak controller] newContent in
            controller?.rootView = makeRoot(newContent)
        }

        presenter.present(controller, animated: false) {
            if !UIView.areAnimationsEnabled {
                UIView.setAnimationsEnabled(true)
            }
        }
    }

    private func dismissPresented() {
        guard let presentedController else { return }
        UIView.setAnimationsEnabled(false)
        presentedController.dismiss(animated: false) {
            if !UIView.areAnimationsEnabled {
                UIView.setAnimationsEnabled(true)
            }
            onDismiss?()
        }
        self.presentedController = nil
        updateContent = nil
    }
}

private struct PresenterAccessor: UIViewControllerRepresentable {
    var onUpdate: (UIViewController) -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        DispatchQueue.main.async {
            onUpdate(uiViewController)
        }
    }
}

private struct FullScreenCoverBackgroundRemovalView: UIViewRepresentable {
    private class BackgroundRemovalView: UIView {
        override func didMoveToWindow() {
            super.didMoveToWindow()
            superview?.superview?.backgroundColor = .clear
        }
    }

    func makeUIView(context: Context) -> UIView {
        return BackgroundRemovalView()
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

#endif
