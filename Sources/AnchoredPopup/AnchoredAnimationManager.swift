//
//  AnchoredAnimationManager.swift
//
//  Created by Alisa Mylnikova on 23.10.2024.
//

import SwiftUI
import Combine

/// this manager stores states for all the paired growing/shrinking animations
@MainActor
class AnchoredAnimationManager: ObservableObject {
    static let shared = AnchoredAnimationManager()

    enum GrowingViewState {
        case hidden, growing, displayed, shrinking
    }

    struct AnimationItem: Equatable {
        var id: String
        var buttonFrame: CGRect
        var state: GrowingViewState
    }

    @Published var animations: [AnimationItem] = []

    private var statePublishers: [String: CurrentValueSubject<AnimationItem?, Never>] = [:]
    private var framePublishers: [String: CurrentValueSubject<AnimationItem?, Never>] = [:]
    private var stateCancellables: [String: AnyCancellable] = [:]
    private var frameCancellables: [String: AnyCancellable] = [:]

    static subscript(id: String) -> AnimationItem? {
        shared.animations.first { $0.id == id }
    }

    func changeStateForAnimation(for id: String, state: GrowingViewState) {
        if let index = animations.firstIndex(where: { $0.id == id }) {
            animations[index].state = state
        }
    }

    func updateFrame(for id: String, frame: CGRect) {
        if let index = animations.firstIndex(where: { $0.id == id }) {
            animations[index].buttonFrame = frame
        } else {
            animations.append(AnimationItem(id: id, buttonFrame: frame, state: .hidden))
        }
    }

    func statePublisher(for id: String) -> CurrentValueSubject<AnimationItem?, Never> {
        if let publisher = statePublishers[id] {
            return publisher
        }

        let subject = CurrentValueSubject<AnimationItem?, Never>(nil)

        stateCancellables[id] = $animations
            .compactMap { animations in animations.first { $0.id == id } }
            .removeDuplicates { $0.state == $1.state }
            .sink { subject.send($0) }

        statePublishers[id] = subject
        return subject
    }

    func framePublisher(for id: String) -> CurrentValueSubject<AnimationItem?, Never> {
        if let publisher = framePublishers[id] {
            return publisher
        }

        let subject = CurrentValueSubject<AnimationItem?, Never>(nil)

        frameCancellables[id] = $animations
            .compactMap { animations in animations.first { $0.id == id } }
            .removeDuplicates { $0.buttonFrame == $1.buttonFrame }
            .sink { subject.send($0) }

        framePublishers[id] = subject
        return subject
    }

}
