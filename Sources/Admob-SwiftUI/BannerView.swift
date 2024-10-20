//
//  BannerViewController.swift
//  Admob-SwiftUI
//
//  Created by Wesley de Groot on 21/08/2024.
//  https://wesleydegroot.nl
//
//  Usage & Example: https://wesleydegroot.nl/blog/post/Admob-in-SwiftUI

import SwiftUI
import GoogleMobileAds
import AppTrackingTransparency
import OSLog

public struct BannerView: View {
    @EnvironmentObject
    var adHelper: AdHelper

    private let logger = Logger(
        subsystem: "nl.wesleydegroot.Admob-SwiftUI",
        category: "BannerView"
    )

    public init() { }

    public var body: some View {
        ZStack {
            AdConsentView()
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    ATTrackingManager.requestTrackingAuthorization(completionHandler: { status in
                        logStatus(status: status)
                    })
                }
                .environmentObject(adHelper)

            if adHelper.haveConsent {
                InternalBannerView(adUnitID: adHelper.adUnitId)
                    .frame(
                        width: GADAdSizeBanner.size.width,
                        height: GADAdSizeBanner.size.height
                    )
                    .opacity(adHelper.showingAd ? 1 : 0)
                    .environmentObject(adHelper)
            }
        }
        .frame(
            width: adHelper.showingAd ? nil : 1,
            height: adHelper.showingAd ? nil : 1
        )
    }

    func logStatus(status: ATTrackingManager.AuthorizationStatus) {
        switch status {
        case .notDetermined:
            logger.debug("Status: Not determined")
        case .authorized:
            logger.debug("Status: Authorized")
        case .denied:
            logger.debug("Status: Denied")
        case .restricted:
            logger.debug("Status: Restricted")
        @unknown default:
            logger.debug("Status: Unknown")
        }
    }
}
