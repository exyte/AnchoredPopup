<a href="https://exyte.com/"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/exyte/media/master/common/header-dark.png"><img src="https://raw.githubusercontent.com/exyte/media/master/common/header-light.png"></picture></a>

<a href="https://exyte.com/"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/exyte/media/master/common/our-site-dark.png" width="80" height="16"><img src="https://raw.githubusercontent.com/exyte/media/master/common/our-site-light.png" width="80" height="16"></picture></a>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<a href="https://twitter.com/exyteHQ"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/exyte/media/master/common/twitter-dark.png" width="74" height="16"><img src="https://raw.githubusercontent.com/exyte/media/master/common/twitter-light.png" width="74" height="16">
</picture></a> <a href="https://exyte.com/contacts"><picture><source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/exyte/media/master/common/get-in-touch-dark.png" width="128" height="24" align="right"><img src="https://raw.githubusercontent.com/exyte/media/master/common/get-in-touch-light.png" width="128" height="24" align="right"></picture></a>

<p float="left">
  <img src="https://github.com/user-attachments/assets/07514304-b4ba-451a-b383-b5cfa3bb67a4" width="200" />
  <img src="https://github.com/user-attachments/assets/fe540201-46f2-44ec-ad9d-5c413f49d6d2" width="200" /> 
  <img src="https://github.com/user-attachments/assets/74ec138c-8695-4819-8455-b32f117a5a1e" width="200" />
</p>

<p><h1 align="left">Anchored Popup</h1></p>

<p><h4>Anchored Popup grows "out" of a trigger view (similar to Hero animation), anchoring to a UnitPoint of the trigger, written with SwiftUI</h4></p>

![](https://img.shields.io/github/v/tag/exyte/anchoredPopup?label=Version)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fexyte%2FAnchoredPopup%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/exyte/AnchoredPopup)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fexyte%2FAnchoredPopup%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/exyte/AnchoredPopup)
[![SPM](https://img.shields.io/badge/SPM-Compatible-brightgreen.svg)](https://swiftpackageindex.com/exyte/AnchoredPopup)
[![License: MIT](https://img.shields.io/badge/License-MIT-black.svg)](https://opensource.org/licenses/MIT)

# Usage

### Minimal example

```swift
import AnchoredPopup

Circle()
    .useAsPopupAnchor(id: "main_menu") {
         MainMenuView()
    }
```

Customized example:
```swift
.useAsPopupAnchor(id: "main_menu") {
    MainMenuView()
} customize: {
    $0.position(.anchorRelative(.bottomLeading))
        .background(.none)
        .isBackgroundPassthrough(true)
        .openOnTap(true)
        .closeOnTap(false)
}
```

### Required parameters - useAsPopupAnchor 
- `id` - A unique `String` to store everything related to this animation, you can use it to manually launch animations using this func `AnchoredPopup.launchAnchoredAnimation`    
- `contentBuilder` - popup body builder

### Optional parameters
- `position` - determines where the popup appears on screen. Available options:
    * `.anchorRelative(UnitPoint, keepInScreenBounds: Bool = true)` - aligns the popup relative to the anchor view at the corresponding proportion; when `keepInScreenBounds` is `true` it will try to keep the popup within the screen safe area
    * `.auto` - like `.anchorRelative(..., keepInScreenBounds: true)`, but automatically picks the best `UnitPoint` (corner) to keep the popup within the safe area
    * `.screenRelative(UnitPoint)` - aligns the popup relative to the whole screen (default: `.center`)
    * `.absolute(UnitPoint, position: CGPoint)` - places the popup at an exact screen coordinate, with `UnitPoint` specifying which part of the popup aligns to that position
- `animation` - appear/disappear animation   
- `openOnTap` - enable/disable opening on tap on the anchor view (default: `true`)  
- `closeOnTap` - enable/disable closing on tap on popup    
- `closeOnTapOutside` - enable/disable closing on tap on popup's background     
- `isBackgroundPassthrough` - enable/disable taps passing through the popup's background     
- `background` - Available options are:     
    * `.none`
    * `.color(Color)`    
    * `.blur(radius: CGFloat)` - blurred fullscreen overlay    
    * `.view(AnyView)` - custom view builder   

## State management pitfall
AnchoredPopup uses `UIWindow` to display itself above anything you might have on screen, so remember - to get adequate UI updates, use `ObservableObjects` or `@Bindings` instead of `@State`. This won't work:
```swift
struct MainView: View {
    @State var name = "Mike"
    var body: some View {
        Text("Show popup")
            .useAsPopupAnchor(id: "a") {
                ZStack {
                    Color.red.size(100)
                    VStack {
                        Text(name)
                        Button("Change text") {
                            name = "John"
                        }
                    }
                }
            } customize: {
                $0.position(.anchorRelative(.bottomLeading))
                    .closeOnTap(false)
            }
    }
}
```
This will work:
```swift
struct MainView: View {
    @State var name = "Mike"
    var body: some View {
        Text("Show popup")
            .useAsPopupAnchor(id: "a") {
                Popup(name: $name)
            } customize: {
                $0.position(.anchorRelative(.bottomLeading))
                    .closeOnTap(false)
            }
    }
}

struct Popup: View {
    @Binding var name: String
    var body: some View {
        ZStack {
            Color.red.size(100)
            VStack {
                Text(name)
                Button("Change text") {
                    name = "John"
                }
            }
        }
    }
}
```
This will work too:
```swift
struct MainView: View {
    var body: some View {
        Text("Show popup")
            .useAsPopupAnchor(id: "a") {
                Popup()
            } customize: {
                $0.position(.anchorRelative(.bottomLeading))
                    .closeOnTap(false)
            }
    }
}

struct Popup: View {
    @State var name = "Mike"
    var body: some View {
        ZStack {
            Color.red.size(100)
            VStack {
                Text(name)
                Button("Change text") {
                    name = "John"
                }
            }
        }
    }
}
```

## Examples

To try AnchoredPopup examples:
- Clone the repo `https://github.com/exyte/AnchoredPopup.git`
- Open `AnchoredPopupExample.xcodeproj`
- Try it!

## Installation

### [Swift Package Manager](https://swift.org/package-manager/)

```swift
dependencies: [
    .package(url: "https://github.com/exyte/AnchoredPopup.git")
]
```

## Requirements

* iOS 16.0+ 

## Our other open source SwiftUI libraries
[PopupView](https://github.com/exyte/PopupView) - Toasts and popups library    
[Grid](https://github.com/exyte/Grid) - The most powerful Grid container     
[AnimatedTabBar](https://github.com/exyte/AnimatedTabBar) - A tabbar with a number of preset animations   
[ScalingHeaderScrollView](https://github.com/exyte/ScalingHeaderScrollView) - A scroll view with a sticky header which shrinks as you scroll  
[MediaPicker](https://github.com/exyte/mediapicker) - Customizable media picker     
[Chat](https://github.com/exyte/chat) - Chat UI framework with fully customizable message cells, input view, and a built-in media picker  
[OpenAI](https://github.com/exyte/OpenAI) Wrapper lib for [OpenAI REST API](https://platform.openai.com/docs/api-reference/introduction)    
[AnimatedGradient](https://github.com/exyte/AnimatedGradient) - Animated linear gradient     
[ConcentricOnboarding](https://github.com/exyte/ConcentricOnboarding) - Animated onboarding flow    
[FloatingButton](https://github.com/exyte/FloatingButton) - Floating button menu    
[ActivityIndicatorView](https://github.com/exyte/ActivityIndicatorView) - A number of animated loading indicators    
[ProgressIndicatorView](https://github.com/exyte/ProgressIndicatorView) - A number of animated progress indicators    
[FlagAndCountryCode](https://github.com/exyte/FlagAndCountryCode) - Phone codes and flags for every country    
[SVGView](https://github.com/exyte/SVGView) - SVG parser    
[LiquidSwipe](https://github.com/exyte/LiquidSwipe) - Liquid navigation animation   
