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
struct ContentView: View {
    @ObservedObject var adHelper = AdHelper(
        adUnitId: "YOUR-AD-UNIT-ID"
    )

    AdView {
            TabView {
                Text("First View")
                    .tabItem {
                        Image(systemName: "1.square.fill")
                        Text("First")
                    }
                UpdateConsent()
                    .tabItem {
                        Image(systemName: "2.square.fill")
                        Text("Second")
                    }
            }
    }
    .environmentObject(adHelper)
}
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

# Contact

We can get in touch via [Mastodon](https://mastodon.social/@0xWDG), [Twitter/X](https://twitter.com/0xWDG), [Discord](https://discordapp.com/users/918438083861573692),[Website](https://wesleydegroot.nl)
