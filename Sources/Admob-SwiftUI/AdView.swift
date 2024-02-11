//
//  AdView.swift
//  Admob-SwiftUI
//
//  Created by Wesley de Groot on 11/02/2024.
//  https://wesleydegroot.nl
//
//  Usage & Example: https://wesleydegroot.nl/blog/post/Admob-in-SwiftUI

import Foundation
import SwiftUI

public struct AdView<Content: View>: View {
    @EnvironmentObject
    var adHelper: AdHelper

    var content: () -> Content

    public init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    public var body: some View {
        ZStack {
            content()
                .addAdPadding(height: adHelper.adHeight)
                .environmentObject(adHelper)

            AdConsentView()
                .environmentObject(adHelper)

            if adHelper.haveConsent {
                VStack {
                    Spacer()
                    BannerView(adUnitID: adHelper.adUnitId)
                        .background(.clear)
                        .frame(width: 320, height: adHelper.adHeight)
                        .padding(.bottom, adHelper.adHeight + 1)
                        .opacity(adHelper.showingAd ? 1 : 0)
                        .environmentObject(adHelper)
                }
            }
        }
    }
}
