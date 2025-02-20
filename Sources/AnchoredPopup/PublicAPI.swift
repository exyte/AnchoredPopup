//
//  PublicAPI.swift
//  AnchoredPopup
//
//  Created by Alisa Mylnikova on 04.02.2025.
//

import SwiftUI

// - MARK: Popup creation

public extension View {
    func useAsPopupAnchor<V: View>(id: String, @ViewBuilder contentBuilder: @escaping () -> V, customize: @escaping (PopupParameters) -> PopupParameters) -> some View {
        self.modifier(TriggerButton(id: id, params: customize(PopupParameters()), contentBuilder: contentBuilder))
    }

    func useAsPopupAnchor<V: View>(id: String, @ViewBuilder contentBuilder: @escaping () -> V) -> some View {
        self.modifier(TriggerButton(id: id, params: PopupParameters(), contentBuilder: contentBuilder))
    }
}

/// convenience methods to open/close the popup manually from code
public class AnchoredPopup {
    @MainActor static func launchGrowingAnimation(id: String) {
        Task {
            await AnchoredAnimationManager.shared.changeStateForAnimation(for: id, state: .growing)
        }
    }

    @MainActor static func launchShrinkingAnimation(id: String) {
        Task {
            await AnchoredAnimationManager.shared.changeStateForAnimation(for: id, state: .shrinking)
        }
    }
}

// - MARK: Customization parameters

public enum AnchoredPopupPosition {
    case anchorRelative(point: UnitPoint) // popup view will be aligned to anchor view at corresponding proportion
    case screenRelative(point: UnitPoint = .center) // popup view will be aligned to whole screen
}

public struct PopupParameters {
    var position: AnchoredPopupPosition = .screenRelative()
    var animation: Animation = .easeOut(duration: 0.3)

    /// Should close on tap anywhere inside the popup
    var closeOnTap: Bool = true

    /// Should close on tap anywhere outside of the popup
    var closeOnTapOutside: Bool = false

    public func position(_ position: AnchoredPopupPosition) -> PopupParameters {
        var params = self
        params.position = position
        return params
    }

    public func animation(_ animation: Animation) -> PopupParameters {
        var params = self
        params.animation = animation
        return params
    }

    /// Should close on tap - default is `true`
    public func closeOnTap(_ closeOnTap: Bool) -> PopupParameters {
        var params = self
        params.closeOnTap = closeOnTap
        return params
    }

    /// Should close on tap outside - default is `false`
    public func closeOnTapOutside(_ closeOnTapOutside: Bool) -> PopupParameters {
        var params = self
        params.closeOnTapOutside = closeOnTapOutside
        return params
    }
}

// - MARK: Environmental dismiss

public typealias SendableClosure = @Sendable @MainActor () -> Void

struct AnchoredPopupDismissKey: EnvironmentKey {
    static let defaultValue: SendableClosure? = nil
}

public extension EnvironmentValues {
    var anchoredPopupDismiss: SendableClosure? {
        get { self[AnchoredPopupDismissKey.self] }
        set { self[AnchoredPopupDismissKey.self] = newValue }
    }
}
