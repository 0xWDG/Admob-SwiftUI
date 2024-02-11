//
//  AdConsent.swift
//  Admob-SwiftUI
//
//  Created by Wesley de Groot on 11/02/2024.
//  https://wesleydegroot.nl
//
//  Usage & Example: https://wesleydegroot.nl/blog/post/Admob-in-SwiftUI

import Foundation
import GoogleMobileAds
import UserMessagingPlatform

/// The Google Mobile Ads SDK provides the User Messaging Platform (Google's
/// IAB Certified consent management platform) as one solution to capture
/// consent for users in GDPR impacted countries. This is an example and
/// you can choose another consent management platform to capture consent.

@MainActor
class GoogleMobileAdsConsentManager: NSObject {
    static let shared = GoogleMobileAdsConsentManager()
    var isMobileAdsStartCalled = false

    var canRequestAds: Bool {
        return UMPConsentInformation.sharedInstance.canRequestAds
    }

    var isPrivacyOptionsRequired: Bool {
        return UMPConsentInformation.sharedInstance.privacyOptionsRequirementStatus == .required
    }

    /// Helper method to call the UMP SDK methods to request consent information and load/present a
    /// consent form if necessary.
    func gatherConsent(
        from consentFormPresentationviewController: UIViewController,
        consentGatheringComplete: @escaping (Error?) -> Void
    ) {
        let parameters = UMPRequestParameters()

        // For testing purposes, you can force a UMPDebugGeography of EEA or not EEA.
        let debugSettings = UMPDebugSettings()
        // debugSettings.geography = UMPDebugGeography.EEA
        parameters.debugSettings = debugSettings

        // Requesting an update to consent information should be called on every app launch.
        UMPConsentInformation.sharedInstance.requestConsentInfoUpdate(
            with: parameters
        ) { requestConsentError in
            guard requestConsentError == nil else {
                return consentGatheringComplete(requestConsentError)
            }

            UMPConsentForm.loadAndPresentIfRequired(
                from: consentFormPresentationviewController
            ) { loadAndPresentError in

                // Consent has been gathered.
                consentGatheringComplete(loadAndPresentError)
            }
        }
    }

    /// Helper method to call the UMP SDK method to present the privacy options form.
    func presentPrivacyOptionsForm(
        from viewController: UIViewController, completionHandler: @escaping (Error?) -> Void
    ) {
        UMPConsentForm.presentPrivacyOptionsForm(
            from: viewController, completionHandler: completionHandler)
    }

    /// Method to initialize the Google Mobile Ads SDK. The SDK should only be initialized once.
    func startGoogleMobileAdsSDK() {
        guard canRequestAds, !isMobileAdsStartCalled else { return }

        isMobileAdsStartCalled = true

        // Initialize the Google Mobile Ads SDK.
        GADMobileAds.sharedInstance().start()
    }
}
