//
//  AnchoredAnimationManager.swift
//
//  Created by Alisa Mylnikova on 23.10.2024.
//

import SwiftUI
import Combine

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

/// this manager stores states for all the paired growing/shrinking animations
@MainActor
class AnchoredAnimationManager: ObservableObject {
    static let shared = AnchoredAnimationManager()

    enum GrowingViewState {
        case hidden, growing, displayed, shrinking
    }

    struct AnimationItem: Equatable {
        var id: String
        var buttonFrame: IntRect
        var state: GrowingViewState

        static func == (lhs: AnimationItem, rhs: AnimationItem) -> Bool {
            lhs.id == rhs.id
            && lhs.buttonFrame == rhs.buttonFrame
            && lhs.state == rhs.state
        }
    }

    @Published var animations: [AnimationItem] = []

    private var publishers: [String: CurrentValueSubject<AnimationItem?, Never>] = [:]
    private var cancellables = Set<AnyCancellable>()

    func changeStateForAnimation(for id: String, state: GrowingViewState) {
        if let index = animations.firstIndex(where: { $0.id == id }) {
            animations[index].state = state
        }
    }

   func updateFrame(for id: String, frame: CGRect) {
        if let index = animations.firstIndex(where: { $0.id == id }) {
            animations[index].buttonFrame = frame.toIntRect()
        } else {
            animations.append(AnimationItem(id: id, buttonFrame: frame.toIntRect(), state: .hidden))
        }
    }

    func publisher(for id: String) -> CurrentValueSubject<AnimationItem?, Never> {
        if let publisher = publishers[id] {
            return publisher
        }

        // Track the last emitted value for comparison
        var lastValue: AnimationItem? = nil

        // Create a CurrentValueSubject to hold the current value
        let subject = CurrentValueSubject<AnimationItem?, Never>(nil)

        // Generate the publisher and handle state changes
        $animations
            .map { animations in
                animations.first { $0.id == id }
            }
            .compactMap { $0 }
            .filter { newItem in
                if let last = lastValue {
                    // Only emit if the item has changed from the last value
                    if last != newItem {
                        lastValue = newItem // Update the last value
                        return true // Emit if there's a change
                    } else {
                        return false // Don't emit if no change
                    }
                } else {
                    lastValue = newItem // Set initial value
                    return true // Emit the first time
                }
            }
            .sink { newItem in
                // Emit the value to the CurrentValueSubject
                subject.send(newItem)
            }
            .store(in: &cancellables)

        publishers[id] = subject
        return subject
    }
}

struct TriggerButton<V>: ViewModifier where V: View {
    var id: String
    var params: PopupParameters
    @ViewBuilder var contentBuilder: () -> V

    @State private var cancellable: AnyCancellable?

    func body(content: Content) -> some View {
        content
            .background(GeometryReader { geo in
                Color.clear
                    .preference(key: ButtonFramePreferenceKey.self, value: ButtonFrameInfo(id: id, frame: geo.frame(in: .global)))
            })
            .simultaneousGesture(
                TapGesture().onEnded { gesture in
                    // trigger displaying animation
                    hideKeyboard()
                    AnchoredAnimationManager.shared.changeStateForAnimation(for: id, state: .growing)
                }
            )
            .onPreferenceChange(ButtonFramePreferenceKey.self) { value in
                if id == value.id {
                    DispatchQueue.main.async {
                        AnchoredAnimationManager.shared.updateFrame(for: value.id, frame: value.frame)
                    }
                }
            }
            .onReceive(AnchoredAnimationManager.shared.publisher(for: id)) { animation in
                if animation?.state == .growing {
                    WindowManager.openNewWindow(id: id, isPassthrough: params.isPassthrough) {
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
//            .task {
//                await AnchoredAnimationManager.shared.subscribeToAnimation(with: id) { animation in
//                    DispatchQueue.main.async {
//
//                    }
//                }
//            }
    }
}

fileprivate struct AnchoredAnimationView<V>: View where V: View {
    var id: String
    var params: PopupParameters
    var contentBuilder: () -> V

    @State private var animatableOpacity: CGFloat = 0
    @State private var animatableScale: CGSize = .zero
    @State private var animatableOffset: CGSize = .zero

    @State private var triggerButtonFrame: IntRect = .zero
    @State private var contentSize: IntSize = .zero

    var body: some View {
        VStack {
            contentBuilder()
                .background(GeometryReader { geo in
                    Color.clear.onAppear {
                        DispatchQueue.main.async {
                            contentSize = geo.size.toIntSize()
                            if let animation = AnchoredAnimationManager.shared.animations.first(where: { $0.id == id }) {
                                setupAndLaunchAnimation(animation)
                            }
                        }
                    }
                })
                .scaleEffect(animatableScale)
                .offset(animatableOffset)
                .position(x: triggerButtonFrame.floatMidX, y: triggerButtonFrame.floatMidY)
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
        .onReceive(AnchoredAnimationManager.shared.publisher(for: id)) { animation in
            if let animation {
                setupAndLaunchAnimation(animation)
            }
        }
    }

    private func setupAndLaunchAnimation(_ animation: AnchoredAnimationManager.AnimationItem) {
        if contentSize == .zero { return }

        if triggerButtonFrame == .zero { // initial setup, and contentSize is ready
            DispatchQueue.main.async {
                triggerButtonFrame = animation.buttonFrame
                setHiddenState()
            }
        }

        DispatchQueue.main.async {
            if animation.state == .growing {
                withAnimation(params.animation) {
                    setDisplayedState()
                } completion: {
                    AnchoredAnimationManager.shared.changeStateForAnimation(for: id, state: .displayed)
                }
            } else if animation.state == .shrinking {
                withAnimation(params.animation) {
                    setHiddenState()
                } completion: {
                    // let the manager know that the animation is finished, this means that transparant sheet can be dismissed
                    AnchoredAnimationManager.shared.changeStateForAnimation(for: id, state: .hidden)
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
        let tw = triggerButtonFrame.floatWidth
        let th = triggerButtonFrame.floatHeight
        let pw = contentSize.floatWidth
        let ph = contentSize.floatHeight
        return CGSize(width: tw/pw, height: th/ph)
    }

    /// starting position is center of the trigger
    private func calculateDisplayedOffset() -> CGSize {
        let cw = contentSize.floatWidth
        let ch = contentSize.floatHeight

        switch params.position {
        case .anchorRelative(let p):
            let tw = triggerButtonFrame.floatWidth
            let th = triggerButtonFrame.floatHeight

            // difference between centers
            let w = cw/2 - tw/2
            let h = ch/2 - th/2

            // normalization: (0, 1) -> (1, -1)
            let px = -2 * p.x + 1
            let py = -2 * p.y + 1

            // the content view center is currently same as anchor view
            // +/- the difference between centers
            return CGSize(width: w * px, height: h * py)

        case .screenRelative(let p):
            let tx = triggerButtonFrame.floatMidX
            let ty = triggerButtonFrame.floatMidY
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
        }
    }
}
