# Admob for SwiftUI

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

We can get in touch via [Twitter/X](https://twitter.com/0xWDG), [Discord](https://discordapp.com/users/918438083861573692), [Mastodon](https://iosdev.space/@0xWDG), [Threads](http://threads.net/@0xwdg), [Bluesky](https://bsky.app/profile/0xwdg.bsky.social).

Alternatively you can visit my [Website](https://wesleydegroot.nl) or my [Blog](https://wdg.codes)
