//
//  BannerLoadState.swift
//  Admob-SwiftUI
//

import CoreGraphics

struct BannerLoadConfiguration: Equatable {
    let adUnitID: String
    let size: CGSize
}

struct BannerLoadState {
    private(set) var loadedConfiguration: BannerLoadConfiguration?

    mutating func shouldLoad(_ configuration: BannerLoadConfiguration) -> Bool {
        guard loadedConfiguration != configuration else { return false }
        loadedConfiguration = configuration
        return true
    }
}
