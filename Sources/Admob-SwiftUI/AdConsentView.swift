//
//  AdConsentView.swift
//  Admob-SwiftUI
//
//  Created by Wesley de Groot on 11/02/2024.
//  https://wesleydegroot.nl
//
//  Usage & Example: https://wesleydegroot.nl/blog/post/Admob-in-SwiftUI

import GoogleMobileAds
import OSLog
import SwiftUI

/// An invisible SwiftUI view that gathers Google User Messaging Platform consent.
///
/// Add this view to a hierarchy that receives an ``AdHelper`` environment
/// object. The view presents a consent form when required, starts Google Mobile
/// Ads when ads may be requested, and updates ``AdHelper/hasConsent`` when the
/// consent flow finishes.
public struct AdConsentView: View {
    @EnvironmentObject
    private var adHelper: AdHelper

    @State
    private var hasViewAppeared = false

    private let logger = Logger(
        subsystem: "nl.wesleydegroot.Admob-SwiftUI",
        category: "AdConsentView"
    )

    /// Creates a consent view.
    ///
    /// The view has no visible content. It must remain in the view hierarchy so
    /// its presentation controller has an attached window when UMP presents a
    /// consent form.
    public init() { }

    /// The invisible presentation host used by the UMP consent flow.
    public var body: some View {
        adHelper.formViewControllerRepresentable
            .frame(width: .zero, height: .zero)
            .task {
                guard !hasViewAppeared else { return }
                hasViewAppeared = true

                await Task.yield()
                guard !Task.isCancelled else { return }
                askConsent()
            }
    }

    func updateConsent() {
        GoogleMobileAdsConsentManager.shared.presentPrivacyOptionsForm(
            from: adHelper.formViewControllerRepresentable.viewController
        ) { formError in
            guard let formError else { return }
            logger.error("Unable to present privacy options: \(formError.localizedDescription)")
        }
    }

    @MainActor
    func askConsent() {
        guard !adHelper.hasConsent else { return }

        logger.debug("Ask for ad consent.")
        GoogleMobileAdsConsentManager.shared.gatherConsent(
            from: adHelper.formViewControllerRepresentable.viewController
        ) { consentError in
            if let consentError {
                logger.fault("Error: \(consentError.localizedDescription)")
            }

            GoogleMobileAdsConsentManager.shared.startGoogleMobileAdsSDK()
            adHelper.hasConsent = GoogleMobileAdsConsentManager.shared.canRequestAds
            logger.debug("Ad consent flow finished. Can request ads: \(adHelper.hasConsent)")
        }

        // This sample attempts to load ads using consent obtained in the previous session.
        GoogleMobileAdsConsentManager.shared.startGoogleMobileAdsSDK()
    }
}

/// Helper to present UMP consent form
///
/// A `UIViewControllerRepresentable` that exposes access to a `UIViewController` reference in
/// SwiftUI.
///
/// `FormViewControllerRepresentable` needs to be included as part of the view hierarchy because
/// to present the UMP consent form, `canPresent(fromRootViewController:)` requires the
/// presenting view controller’s window value to not be nil.
struct FormViewControllerRepresentable: UIViewControllerRepresentable {
    let viewController = UIViewController()

    func makeUIViewController(context: Context) -> some UIViewController {
        viewController
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}
