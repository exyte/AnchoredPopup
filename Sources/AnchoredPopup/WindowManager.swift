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
    var windows: [String: UIWindow] = [:]

    static func openNewWindow<Content: View>(id: String, closeOnTapOutside: Bool, isPassthrough: Bool, content: ()->Content) {
		guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
			print("No valid scene available")
			return
		}

        let window = UIPassthroughWindow(windowScene: scene, id: id, closeOnTapOutside: closeOnTapOutside, isPassthrough: isPassthrough)
        window.backgroundColor = .clear
        let root = content()
            .environment(\.anchoredPopupDismiss) {
                AnchoredAnimationManager.shared.changeStateForAnimation(for: id, state: .shrinking)
            }
        let controller = UIHostingController(rootView: root)
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
    var id: String
    var closeOnTapOutside: Bool
    var isPassthrough: Bool

    init(windowScene: UIWindowScene, id: String, closeOnTapOutside: Bool, isPassthrough: Bool) {
        self.id = id
        self.closeOnTapOutside = closeOnTapOutside
        self.isPassthrough = isPassthrough
        super.init(windowScene: windowScene)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let vc = self.rootViewController else {
            return nil // pass to next window
        }
        
        vc.view.layoutIfNeeded() // otherwise the frame is as if the popup is still outside the screen
        
        let layerHitTestResult = vc.view.layer.hitTest(vc.view.convert(point, from: self))
        let superlayerDelegateName = layerHitTestResult?.superlayer?.delegate.map { String(describing: type(of: $0)) }
        let didTapBackground = superlayerDelegateName?.contains(String(describing: PopupHitTestingBackground.self)) ?? false
        
        if didTapBackground {
            if closeOnTapOutside {
                AnchoredAnimationManager.shared.changeStateForAnimation(for: id, state: .shrinking)
            }
            
            if isPassthrough {
                return nil // pass to next window
            }
            return vc.view
        }
        
        // pass tap to this
        let farthestDescendent = super.hitTest(point, with: event)
        return farthestDescendent
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
