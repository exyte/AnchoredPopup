//
//  Utils.swift
//  AnchoredPopup
//
//  Created by Alisa Mylnikova on 21.01.2025.
//

import SwiftUI

@MainActor func hideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}

// MARK: - Root metrics

/// Live safe area insets and size of the app's real window, kept up to date by `ScreenMetricsReader`
/// regardless of whether a popup ends up presented via `.window` or `.sheet`. A popup's own
/// window/full screen cover deliberately opts out of safe area resolution (`safeAreaRegions = []`)
/// to avoid an async settling glitch, so it cannot measure its own safe area reliably - it reads
/// these published values instead, which keeps the popup correctly positioned through rotation
/// and fold-state changes (e.g. on iPhone Duo).
@MainActor
final class AnchoredPopupMetrics: ObservableObject {
    static let shared = AnchoredPopupMetrics()

    @Published var safeAreaInsets: EdgeInsets = EdgeInsets()
    @Published var contentSize: CGSize = .zero
}

/// Measures the real app window `TriggerButton` lives in - not a window of our own - and keeps
/// `AnchoredPopupMetrics` current. Reads `window.bounds`/`window.safeAreaInsets` from inside UIKit's
/// own layout/safe-area callbacks (not a one-off imperative read), so the values stay correct
/// across rotation and fold-state changes before any popup picks a display mode.
struct ScreenMetricsReader: UIViewRepresentable {
    final class TrackingView: UIView {
        override func didMoveToWindow() {
            super.didMoveToWindow()
            report()
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            report()
        }

        override func safeAreaInsetsDidChange() {
            super.safeAreaInsetsDidChange()
            report()
        }

        private func report() {
            guard let window else { return }
            let size = window.bounds.size
            let insets = EdgeInsets(
                top: window.safeAreaInsets.top,
                leading: window.safeAreaInsets.left,
                bottom: window.safeAreaInsets.bottom,
                trailing: window.safeAreaInsets.right
            )

            // `report()` can run while SwiftUI is still mid-update (e.g. from `layoutSubviews`),
            // so defer the `@Published` writes to avoid "Publishing changes from within view updates"
            DispatchQueue.main.async {
                AnchoredPopupMetrics.shared.contentSize = size
                AnchoredPopupMetrics.shared.safeAreaInsets = insets
            }
        }
    }

    func makeUIView(context: Context) -> TrackingView {
        TrackingView()
    }

    func updateUIView(_ uiView: TrackingView, context: Context) {}
}

// MARK: - Frame getting

struct ButtonFrameInfo: Equatable {
    let id: String
    let frame: CGRect
}

struct ButtonFramePreferenceKey: PreferenceKey {
    typealias Value = ButtonFrameInfo
    static let defaultValue: ButtonFrameInfo = ButtonFrameInfo(id: "", frame: .zero)

    static func reduce(value: inout ButtonFrameInfo, nextValue: () -> ButtonFrameInfo) {
        let next = nextValue()
        if value != next {
            value = next
        }
    }
}

// MARK: - AnimatedBackgroundView

struct AnimatedBackgroundView: View {
    var id: String
    var background: AnchoredPopupBackground

    @State private var animatableOpacity: CGFloat = 0

    var body: some View {
        ZStack {
            Group {
                switch background {
                case .none:
                    EmptyView()
                case .color(let color):
                    color
                case .blur(let radius):
                    Blur(radius: radius)
                case .view(let anyView):
                    anyView
                }
            }
            .ignoresSafeArea()
            .opacity(animatableOpacity)
            .onReceive(AnchoredAnimationManager.shared.statePublisher(for: id)) { animation in
                if let animation {
                    setupAndLaunchAnimation(animation)
                }
            }

            PopupHitTestingBackground()
                .ignoresSafeArea()
        }
    }

    private func setupAndLaunchAnimation(_ animation: AnchoredAnimationManager.AnimationItem) {
        Task { @MainActor in
            withAnimation(.easeInOut(duration: 0.2)) {
                if animation.state == .growing {
                    setDisplayedState()
                } else if animation.state == .shrinking {
                    setHiddenState()
                }
            }
        }
    }

    private func setHiddenState() {
        animatableOpacity = 0
    }

    private func setDisplayedState() {
        animatableOpacity = 1
    }
}

/// A special view to handle hit-testing on background parts of popup content
struct PopupHitTestingBackground: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
