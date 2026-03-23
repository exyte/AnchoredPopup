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

// MARK: - Frame getting

struct ButtonFrameInfo: Equatable {
    let id: String
    let frame: CGRect
}

struct ButtonFramePreferenceKey: PreferenceKey {
    typealias Value = ButtonFrameInfo
    static let defaultValue: ButtonFrameInfo = ButtonFrameInfo(id: "", frame: .zero)

    static func reduce(value: inout ButtonFrameInfo, nextValue: () -> ButtonFrameInfo) {
        if value != nextValue() {
            value = nextValue()
        }
    }
}

// MARK: - AnimatedBackgroundView

struct AnimatedBackgroundView: View {
    @Binding var id: String
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
        DispatchQueue.main.async {
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

// MARK: - IntRect

struct IntRect: Equatable {
    var midX, midY, width, height: Int
    var floatMidX: CGFloat { CGFloat(midX) }
    var floatMidY: CGFloat { CGFloat(midY) }
    var floatWidth: CGFloat { CGFloat(width) }
    var floatHeight: CGFloat { CGFloat(height) }

    static let zero = IntRect(midX: 0, midY: 0, width: 0, height: 0)

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.midX == rhs.midX
        && lhs.midY == rhs.midY
        && lhs.width == rhs.width
        && lhs.height == rhs.height
    }
}

extension CGRect {
    func toIntRect() -> IntRect {
        IntRect(midX: Int(midX), midY: Int(midY), width: Int(width), height: Int(height))
    }
}

struct IntSize: Equatable {
    var width, height: Int
    var floatWidth: CGFloat { CGFloat(width) }
    var floatHeight: CGFloat { CGFloat(height) }

    static let zero = IntSize(width: 0, height: 0)

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.width == rhs.width
        && lhs.height == rhs.height
    }
}

extension CGSize {
    func toIntSize() -> IntSize {
        IntSize(width: Int(width), height: Int(height))
    }
}
