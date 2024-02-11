//
//  AdHelper.swift
//  Admob-SwiftUI
//
//  Created by Wesley de Groot on 11/02/2024.
//  https://wesleydegroot.nl
//
//  Usage & Example: https://wesleydegroot.nl/blog/post/Admob-in-SwiftUI

import SwiftUI
import GoogleMobileAds
import UserMessagingPlatform

open class AdHelper: ObservableObject {
    @Published public var haveConsent: Bool = false
    @Published public var showingAd: Bool = true
    @Published public var adUnitId: String = ""
    @Published public var adWidth: CGFloat = .zero

    public var updateConsent: (() -> Void) = { }

    public init(adUnitId: String) {
        self.adUnitId = adUnitId
    }

    public var adHeight: CGFloat {
        if !haveConsent {
            return 0
        }

//        if UIDevice.current.userInterfaceIdiom == .pad {
//            UserDefaults.standard.setValue(90, forKey: "_as")
//            return 89
//        }

        return 49
    }

    public func resetConsent() {
        UMPConsentInformation.sharedInstance.reset()
    }

    public func debug() {
        GADMobileAds
            .sharedInstance()
            .requestConfiguration
            .testDeviceIdentifiers = [
                // Find a way to enable all devices.
                "2077ef9a63d2b398840261c8221a0c9b"
            ]
    }
}
