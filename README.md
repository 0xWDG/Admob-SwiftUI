# Admob for SwiftUI

This library helps you to easily integrate the Admob SDK in your SwiftUI app. It is a wrapper around the Google Mobile Ads SDK for iOS. It provides a SwiftUI view that you can use to display banner ads in your app above your tabbar.
See my blog post for more information: https://wesleydegroot.nl/blog/post/Admob-in-SwiftUI


## Requirements

- Swift 5.9+ (Xcode 15+)
- iOS 15+

## Installation

Install using Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/0xWDG/Admob-SwiftUI.git", .branch("main")),
],
targets: [
    .target(name: "MyTarget", dependencies: [
        .product(name: "Admob_SwiftUI", package: "Admob_SwiftUI"),
    ]),
]
```

And import it:
```swift
import Admob_SwiftUI
```

# Usage
```swift
struct MyApp: App {
    @StateObject var adHelper = AdHelper(
        adUnitID: "YOUR-AD-UNIT-ID"
    )

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(adHelper)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject
    var adHelper: AdHelper

    var body: some View {
        AdView {
            TabView {
                UpdateConsent()
                    .tabItem {
                        Image(systemName: "2.square.fill")
                        Text("Second")
                    }

                SecondView()
                    .tabItem {
                        Image(systemName: "1.square.fill")
                        Text("First")
                    }
            }
        }
    }
}

struct SecondView: View {
    @EnvironmentObject
    var adHelper: AdHelper

    var body: some View {
        BannerView() // A banner view.
    }
}
```

Request App Tracking Transparency authorization explicitly from your app after
showing any explanatory UI:

```swift
let status = await AdTrackingAuthorization.request()
```

**Reset/Update Consent**
```Swift
struct UpdateConsent: View {
    @EnvironmentObject
    private var adHelper: AdHelper

    var body: some View {
        ScrollView {
            VStack {
                Button("Reset consent", role: .destructive) {
                    adHelper.resetConsent()
                }

                Button("Update Consent") {
                    adHelper.updateConsent()
                }
            }
        }
    }
}
```

## Contact

🦋 [@0xWDG](https://bsky.app/profile/0xWDG.bsky.social)
🐘 [mastodon.social/@0xWDG](https://mastodon.social/@0xWDG)
🐦 [@0xWDG](https://x.com/0xWDG)
🧵 [@0xWDG](https://www.threads.net/@0xWDG)
🌐 [wesleydegroot.nl](https://wesleydegroot.nl)
🤖 [Discord](https://discordapp.com/users/918438083861573692)

Interested learning more about Swift? [Check out my blog](https://wesleydegroot.nl/blog/).
