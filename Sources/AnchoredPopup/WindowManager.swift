//
//  WindowManager.swift
//  Beyond
//
//  Created by Alisa Mylnikova on 19.12.2024.
//

import SwiftUI

@MainActor
final class WindowManager {
	static let shared = WindowManager()
    private var windows: [String: UIWindow] = [:]

    static func openNewWindow<Content: View>(id: String, isPassthrough: Bool, content: ()->Content) {
		guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
			print("No valid scene available")
			return
		}

        let window = isPassthrough ? UIPassthroughWindow(windowScene: scene) : UIWindow(windowScene: scene)
        window.backgroundColor = .clear
        let root = content()
            .environment(\.anchoredPopupDismiss) {
                Task {
                    await AnchoredAnimationManager.shared.changeStateForAnimation(for: id, state: .shrinking)
                }
            }
        let controller = isPassthrough ? UIPassthroughVC(rootView: root) : UIHostingController(rootView: root)
        controller.view.backgroundColor = .clear
        window.rootViewController = controller
		window.windowLevel = .alert + 1
		window.makeKeyAndVisible()
        shared.windows[id] = window
	}

    static func closeWindow(id: String) {
        shared.windows[id]?.isHidden = true
        shared.windows.removeValue(forKey: id)
	}
}

class UIPassthroughWindow: UIWindow {

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let vc = self.rootViewController {
            vc.view.layoutSubviews() // otherwise the frame is as if the popup is still outside the screen
            if let _ = isTouchInsideSubview(point: point, vc: vc.view) {
                // pass tap to this UIPassthroughVC
                return vc.view
            }
        }
        return nil // pass to next window
    }

    private func isTouchInsideSubview(point: CGPoint, vc: UIView) -> UIView? {
        for subview in vc.subviews {
            if subview.frame.contains(point) {
                return subview
            }
        }
        return nil
    }
}

class UIPassthroughVC<Content: View>: UIHostingController<Content> {

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Check if any touch is inside one of the subviews, if so, ignore it
        if !isTouchInsideSubview(touches) {
            // If touch is not inside any subview, pass the touch to the next responder
            super.touchesBegan(touches, with: event)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !isTouchInsideSubview(touches) {
            super.touchesMoved(touches, with: event)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !isTouchInsideSubview(touches) {
            super.touchesEnded(touches, with: event)
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !isTouchInsideSubview(touches) {
            super.touchesCancelled(touches, with: event)
        }
    }

    // Helper function to determine if any touch is inside a subview
    private func isTouchInsideSubview(_ touches: Set<UITouch>) -> Bool {
        guard let touch = touches.first else {
            return false
        }

        let touchLocation = touch.location(in: self.view)

        // Iterate over all subviews to check if the touch is inside any of them
        for subview in self.view.subviews {
            if subview.frame.contains(touchLocation) {
                return true
            }
        }
        return false
    }
}
