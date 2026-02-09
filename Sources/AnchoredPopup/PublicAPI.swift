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
    @MainActor public static func launchGrowingAnimation(id: String) {
        AnchoredAnimationManager.shared.changeStateForAnimation(for: id, state: .growing)
    }

    @MainActor public static func launchShrinkingAnimation(id: String) {
        AnchoredAnimationManager.shared.changeStateForAnimation(for: id, state: .shrinking)
    }
}

// - MARK: Customization parameters

public enum AnchoredPopupPosition {
    case anchorRelative(_ point: UnitPoint, keepInScreenBounds: Bool = true) // popup view will be aligned to anchor view at corresponding proportion
    case auto // similar to `anchorRelative(..., keepInScreenBounds: true)` but auto-picks the best anchor `UnitPoint` to keep the popup within safe area
    case screenRelative(_ point: UnitPoint = .center) // popup view will be aligned to whole screen
    case absolute(_ point: UnitPoint, position: CGPoint) // popup will be placed at exact screen position, with point specifying which part of popup aligns to that position
}

public enum AnchoredPopupBackground {
    case none
    case color(Color)
    case blur(radius: CGFloat = 6)
    case view(AnyView)

    // Convenience initializer for `view` that automatically wraps the content in `AnyView`
    public init<Content: View>(viewBuilder: @escaping () -> Content) {
        self = .view(AnyView(viewBuilder()))
    }
}

public struct PopupParameters {
    var position: AnchoredPopupPosition = .screenRelative()
    var animation: Animation = .easeIn(duration: 0.3)

    /// Should open popup on tap on the anchor view
    var openOnTap: Bool = true

    /// Should close on tap anywhere inside the popup
    var closeOnTap: Bool = true

    /// Should close on tap anywhere outside of the popup
    var closeOnTapOutside: Bool = false

    /// Should taps pass through the popup's background
    var isPassthrough: Bool = false

    var background: AnchoredPopupBackground = .blur()

    public func position(_ position: AnchoredPopupPosition) -> PopupParameters {
        var params = self
        params.position = position
        return params
    }

    /// Appear/disappear animation - default is `easeOut`
    public func animation(_ animation: Animation) -> PopupParameters {
        var params = self
        params.animation = animation
        return params
    }

    /// Should open popup on tap on the anchor view - default is `true`
    public func openOnTap(_ openOnTap: Bool) -> PopupParameters {
        var params = self
        params.openOnTap = openOnTap
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

    /// Should taps pass through the popup's background - default is `false`
    public func isBackgroundPassthrough(_ isPassthrough: Bool) -> PopupParameters {
        var params = self
        params.isPassthrough = isPassthrough
        return params
    }

    /// Background for popup - default is `.blur`
    public func background(_ background: AnchoredPopupBackground) -> PopupParameters {
        var params = self
        params.background = background
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
