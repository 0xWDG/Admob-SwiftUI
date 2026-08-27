//
//  BannerViewController.swift
//  Admob-SwiftUI
//
//  Created by Wesley de Groot on 21/08/2024.
//  https://wesleydegroot.nl
//
//  Usage & Example: https://wesleydegroot.nl/blog/post/Admob-in-SwiftUI

import GoogleMobileAds
import SwiftUI

/// Displays an adaptive Google Mobile Ads banner after consent is available.
///
/// The view gathers UMP consent through ``AdConsentView`` and creates the
/// underlying banner only when ``AdHelper/hasConsent`` is `true`. It does not
/// request App Tracking Transparency authorization; use
/// ``AdTrackingAuthorization`` explicitly from the host app.
public struct BannerView<BackupView: View>: View {
    @EnvironmentObject
    private var adHelper: AdHelper

    @ViewBuilder private let backupView: BackupView?

    /// Creates a banner view with optional fallback content.
    ///
    /// - Parameter backupView: Content displayed behind the Google banner while
    ///   no ad has been rendered. The default produces no fallback content.
    public init(@ViewBuilder backupView: () -> BackupView? = { nil }) {
        self.backupView = backupView()
    }

    /// The consent host and adaptive banner content.
    public var body: some View {
        ZStack {
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] != "1" {
                AdConsentView()
            }

            if adHelper.hasConsent {
                InternalBannerView {
                    backupView
                }
                .frame(maxWidth: .infinity)
                .frame(height: adHelper.adHeight)
            }
        }
        .environmentObject(adHelper)
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
