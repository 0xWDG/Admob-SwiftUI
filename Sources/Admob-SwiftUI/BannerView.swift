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

public struct BannerView<BackupView: View>: View {
    @EnvironmentObject
    var adHelper: AdHelper

    var backupView: (() -> BackupView)?

    private let logger = Logger(
        subsystem: "nl.wesleydegroot.Admob-SwiftUI",
        category: "BannerView"
    )

    public init(backupView: (() -> BackupView)? = nil) {
        self.backupView = backupView
    }

    public var body: some View {
        ZStack {
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
                AdConsentView()
                    .onReceive(
                        NotificationCenter
                            .default
                            .publisher(
                                for: UIApplication.didBecomeActiveNotification
                            )
                    ) { _ in
                        ATTrackingManager.requestTrackingAuthorization(
                            completionHandler: { logStatus(status: $0) }
                        )
                    }
            }

            if adHelper.haveConsent {
                InternalBannerView(backupView: backupView)
                    .frame(maxWidth: adHelper.adWidth, maxHeight: adHelper.adHeight)
            }
        }
        .environmentObject(adHelper)
        .frame(
            width: adHelper.showingAd ? nil : 1,
            height: adHelper.showingAd ? nil : 1
        )
    }

    func logStatus(status: ATTrackingManager.AuthorizationStatus) {
        switch status {
        case .notDetermined:
            logger.debug("ATTrackingManager status: Not determined")
        case .authorized:
            logger.debug("ATTrackingManager status: Authorized")
        case .denied:
            logger.debug("ATTrackingManager status: Denied")
        case .restricted:
            logger.debug("ATTrackingManager status: Restricted")
        @unknown default:
            logger.debug("ATTrackingManager status: Unknown")
        }
    }
}

#Preview {
    VStack {
        Text("Top content")

        BannerView {
            Button {
                print("Pressed the button")
            } label: {
                Text("Don't like ads?")
            }
        }

        Text("Bottom content")
    }
}
