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
import Combine

/// Stores shared banner configuration, consent state, and presentation state.
///
/// Create one helper for an ad placement and inject it into the SwiftUI
/// environment. Banner views observe this object for consent and layout changes.
/// Reassigning a banner value to its existing value does not invalidate SwiftUI.
@MainActor
open class AdHelper: ObservableObject {
    /// Logger
    private let logger = Logger(
        subsystem: "nl.wesleydegroot.Admob-SwiftUI",
        category: "AdHelper"
    )

    /// Whether Google User Messaging Platform currently allows ads to be requested.
    ///
    /// ``AdConsentView`` updates this value when its consent flow finishes.
    @Published
    public var hasConsent = false

    private var bannerPresentationState = BannerPresentationState()
    private var storedAdUnitID: String

    /// Whether a banner ad is currently loaded and being displayed.
    ///
    /// Assignments are equality-checked to avoid unnecessary SwiftUI updates.
    public var showingAd: Bool {
        get { bannerPresentationState.isShowingAd }
        set { updateBannerPresentation(isShowingAd: newValue) }
    }

    /// The Google Mobile Ads unit identifier used by banner views.
    ///
    /// Assigning the same identifier does not invalidate observing views.
    public var adUnitID: String {
        get { storedAdUnitID }
        set {
            guard newValue != storedAdUnitID else { return }
            objectWillChange.send()
            storedAdUnitID = newValue
        }
    }

    /// The width of the most recently loaded banner, in points.
    ///
    /// Assignments update ``adSize`` and notify observers only when the resulting
    /// size differs from the current banner size.
    public var adWidth: CGFloat {
        get { bannerPresentationState.size.width }
        set {
            updateBannerPresentation(
                isShowingAd: showingAd,
                size: CGSize(width: newValue, height: adHeight)
            )
        }
    }

    /// The height of the most recently loaded banner, in points.
    ///
    /// Banner containers use this value to reserve the correct amount of space.
    public var adHeight: CGFloat {
        get { bannerPresentationState.size.height }
        set {
            updateBannerPresentation(
                isShowingAd: showingAd,
                size: CGSize(width: adWidth, height: newValue)
            )
        }
    }

    /// The size of the most recently loaded banner, in points.
    ///
    /// Assigning the existing size does not invalidate observing views.
    public var adSize: CGSize {
        get { bannerPresentationState.size }
        set { updateBannerPresentation(isShowingAd: showingAd, size: newValue) }
    }

    let formViewControllerRepresentable = FormViewControllerRepresentable()

    /// Presents the Google User Messaging Platform privacy options form.
    ///
    /// This closure is configured by the helper outside SwiftUI previews. Call
    /// it from a user-initiated action when privacy options should be revisited.
    @MainActor
    public var updateConsent: (() -> Void) = {}

    /// Creates shared ad state for a banner ad unit.
    ///
    /// An empty identifier uses Google's test banner identifier. The helper does
    /// not request consent or load an ad until it is consumed by an ad view.
    ///
    /// - Parameter adUnitID: The Google Mobile Ads unit identifier.
    public init(adUnitID: String) {
        storedAdUnitID = adUnitID.isEmpty ? "ca-app-pub-3940256099942544/2934735716" : adUnitID

        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            hasConsent = true
        } else {
            updateConsent = { [weak self] in
                guard let self else { return }

                GoogleMobileAdsConsentManager.shared.presentPrivacyOptionsForm(
                    from: self.formViewControllerRepresentable.viewController
                ) { formError in
                    guard let formError else { return }
                    self.logger.fault("Error presentPrivacyOptionsForm: \(formError.localizedDescription)")
                }
            }
        }
    }

    /// Resets locally cached UMP consent information.
    ///
    /// After resetting, ``hasConsent`` becomes `false`. A subsequent
    /// ``AdConsentView`` appearance starts a new consent information request.
    public func resetConsent() {
        UMPConsentInformation.sharedInstance.reset()
        hasConsent = false
    }

    func updateBannerPresentation(isShowingAd: Bool, size: CGSize? = nil) {
        var updatedState = bannerPresentationState
        updatedState.isShowingAd = isShowingAd

        if let size {
            updatedState.size = size
        }

        guard updatedState != bannerPresentationState else { return }
        objectWillChange.send()
        bannerPresentationState = updatedState
    }

    /// Configures Google's sample test-device identifier.
    ///
    /// This helper is intended only for development. Production applications
    /// should configure their own test device identifiers explicitly and should
    /// not call this method for release builds.
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

public extension AdHelper {
    /// A deprecated compatibility alias for ``hasConsent``.
    ///
    /// New code should read and write ``hasConsent`` directly.
    @available(*, deprecated, renamed: "hasConsent")
    var haveConsent: Bool {
        get { hasConsent }
        set { hasConsent = newValue }
    }

    /// A deprecated compatibility alias for ``adUnitID``.
    ///
    /// New code should use the correctly capitalized ``adUnitID`` property.
    @available(*, deprecated, renamed: "adUnitID")
    var adUnitId: String {
        get { adUnitID }
        set { adUnitID = newValue }
    }

    /// Creates an ad helper using the deprecated `adUnitId` argument label.
    ///
    /// - Parameter adUnitId: The Google Mobile Ads unit identifier.
    @available(*, deprecated, renamed: "init(adUnitID:)")
    convenience init(adUnitId: String) {
        self.init(adUnitID: adUnitId)
    }
}
