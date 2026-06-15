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

    private var isMobileAdsStartCalled = false
    private var completionQueue = ConsentCompletionQueue()

    var canRequestAds: Bool {
        UMPConsentInformation.sharedInstance.canRequestAds
    }

    var isPrivacyOptionsRequired: Bool {
        UMPConsentInformation.sharedInstance.privacyOptionsRequirementStatus == .required
    }

    /// Helper method to call the UMP SDK methods to request consent information and load/present a
    /// consent form if necessary.
    func gatherConsent(
        from consentFormPresentationviewController: UIViewController,
        consentGatheringComplete: @MainActor @Sendable @escaping (Error?) -> Void
    ) {
        guard completionQueue.enqueue(consentGatheringComplete) else { return }

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
                Task { @MainActor in
                    self.finishGatheringConsent(with: requestConsentError)
                }
                return
            }

            UMPConsentForm.loadAndPresentIfRequired(
                from: consentFormPresentationviewController
            ) { loadAndPresentError in
                Task { @MainActor in
                    self.finishGatheringConsent(with: loadAndPresentError)
                }
            }
        }
    }

    private func finishGatheringConsent(with error: Error?) {
        completionQueue.finish(with: error)
    }

    /// Helper method to call the UMP SDK method to present the privacy options form.
    func presentPrivacyOptionsForm(
        from viewController: UIViewController,
        completionHandler: @MainActor @Sendable @escaping (Error?) -> Void
    ) {
        UMPConsentForm.presentPrivacyOptionsForm(
            from: viewController
        ) { error in
            Task { @MainActor in
                completionHandler(error)
            }
        }
    }

    /// Method to initialize the Google Mobile Ads SDK. The SDK should only be initialized once.
    func startGoogleMobileAdsSDK() {
        guard canRequestAds, !isMobileAdsStartCalled else { return }

        isMobileAdsStartCalled = true

        // Initialize the Google Mobile Ads SDK.
        GADMobileAds.sharedInstance().start()
    }
}
