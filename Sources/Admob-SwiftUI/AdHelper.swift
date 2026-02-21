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
import OSLog

/// Ad helper
open class AdHelper: ObservableObject {
    /// Logger
    private let logger = Logger(
        subsystem: "nl.wesleydegroot.Admob-SwiftUI",
        category: "AdHelper"
    )

    public var identifier: UUID = .init()

    /// Do we have consent to show ads
    @Published
    public var haveConsent: Bool = false

    /// Are we showing an ad?
    @Published
    public var showingAd: Bool = true

    /// Ad unit id
    @Published
    public var adUnitId: String = ""

    /// Ad width
    @Published
    public var adWidth: CGFloat = GADAdSizeBanner.size.width

    /// The ad height
    @Published
    public var adHeight: CGFloat = GADAdSizeBanner.size.height

    /// Ad width
    @Published
    public var adSize: CGSize = GADAdSizeBanner.size

    /// Are we started already
    public static var isStarted = false

    let formViewControllerRepresentable = FormViewControllerRepresentable()

    /// Update consent
    @MainActor
    public var updateConsent: (() -> Void) = {}

    /// Initialize with ad unit id.
    ///
    /// - Parameters:
    ///   - adUnitId: The Ad unit identifier.
    public init(adUnitId: String) {
        if !AdHelper.isStarted {
            self.adUnitId = adUnitId.isEmpty ? "ca-app-pub-3940256099942544/2934735716" : adUnitId
            AdHelper.isStarted = true
        } else {
            logger.fault("AdHelper is already started.\r\nThis can cause unexpected behaviour.")
        }

        Task { @MainActor in
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
                // Previews doesn't like this
                self.haveConsent = true
                self.updateConsent = { }
            } else {
                self.updateConsent = {
                    GoogleMobileAdsConsentManager.shared.presentPrivacyOptionsForm(
                        from: self.formViewControllerRepresentable.viewController
                    ) { (formError) in
                        guard let formError else { return }

                        Logger(
                            subsystem: "nl.wesleydegroot.Admob-SwiftUI",
                            category: "AdHelper"
                        )
                        .fault("Error presentPrivacyOptionsForm: \(formError.localizedDescription)")
                    }
                }
            }
        }
    }

    /// Reset consent
    public func resetConsent() {
        UMPConsentInformation.sharedInstance.reset()
    }

    /// (not in use) Debug feature.
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
