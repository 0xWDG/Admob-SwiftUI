//
//  AdConsentView.swift
//  Admob-SwiftUI
//
//  Created by Wesley de Groot on 11/02/2024.
//  https://wesleydegroot.nl
//
//  Usage & Example: https://wesleydegroot.nl/blog/post/Admob-in-SwiftUI

import SwiftUI
import GoogleMobileAds
import OSLog

public struct AdConsentView: View {
    @EnvironmentObject
    private var adHelper: AdHelper

    @State
    private var hasViewAppeared = false

    private let logger = Logger(
        subsystem: "nl.wesleydegroot.Admob-SwiftUI",
        category: "AdConsentView"
    )

    var formViewControllerRepresentableView: some View {
        adHelper.formViewControllerRepresentable
            .frame(width: .zero, height: .zero)
    }

    public init() { }

    public var body: some View {
        VStack { }
        .background(formViewControllerRepresentableView)
        .onAppear {
            guard !hasViewAppeared else { return }
            hasViewAppeared = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.askConsent()
            }
        }
    }

    func updateConsent() {
        GoogleMobileAdsConsentManager.shared.presentPrivacyOptionsForm(
            from: adHelper.formViewControllerRepresentable.viewController
        ) { (formError) in
            guard let formError else { return }
            print(formError.localizedDescription)
        }
    }

    @MainActor
    func askConsent() {
//        adHelper.updateConsent = updateConsent

        logger.debug("Ask for ad consent.")
        GoogleMobileAdsConsentManager.shared.gatherConsent(
            from: adHelper.formViewControllerRepresentable.viewController
        ) { (consentError) in
            if let consentError {
                // Consent gathering failed.
                logger.fault("Error: \(consentError.localizedDescription)")
            }

            GoogleMobileAdsConsentManager.shared.startGoogleMobileAdsSDK()
        }

        // This sample attempts to load ads using consent obtained in the previous session.
        GoogleMobileAdsConsentManager.shared.startGoogleMobileAdsSDK()

        adHelper.haveConsent = true
        logger.debug("we have ad consent.")
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
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}
