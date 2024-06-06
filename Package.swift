// swift-tools-version:5.5

//  Admob-SwiftUI
//
//  Created by Wesley de Groot on 11/02/2024.
//  https://wesleydegroot.nl
//
//  Usage & Example: https://wesleydegroot.nl/blog/post/Admob-in-SwiftUI

import PackageDescription

let package = Package(
    name: "Admob-SwiftUI",

    defaultLocalization: "en",

    platforms: [
        .iOS(.v15)
    ],

    products: [
        .library(
            name: "Admob-SwiftUI",
            targets: ["Admob-SwiftUI"]
        )
    ],

    dependencies: [
        .package(
            name: "GoogleMobileAds",
            url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git",
            from: "11.2.0"
        )
    ],

    targets: [
        .target(
            name: "Admob-SwiftUI",
            dependencies: [
                "GoogleMobileAds"
                ],
            exclude: [],
            resources: []
        )
    ]
)

#if swift(>=5.6)
  // Add the documentation compiler plugin if possible
  package.dependencies.append(
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0")
  )
#endif
