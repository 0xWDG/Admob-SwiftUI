//
//  BannerView.swift
//  Admob-SwiftUI
//
//  Created by Wesley de Groot on 11/02/2024.
//  https://wesleydegroot.nl
//
//  Usage & Example: https://wesleydegroot.nl/blog/post/Admob-in-SwiftUI

import SwiftUI
import GoogleMobileAds

struct BannerView: UIViewControllerRepresentable {
    @EnvironmentObject
    private var adHelper: AdHelper

    @State
    private var viewWidth: CGFloat = .zero

    @State
    var adUnitID: String

    private let bannerView = GADBannerView()

    func makeUIViewController(context: Context) -> some UIViewController {
        let bannerViewController = BannerViewController()
        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = bannerViewController
        bannerView.delegate = context.coordinator

        bannerViewController.view.backgroundColor = .clear
        bannerViewController.view.addSubview(bannerView)
        bannerViewController.delegate = context.coordinator

        return bannerViewController
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        guard viewWidth != .zero else {
            return
        }

        // Request a banner ad with the updated viewWidth.
        bannerView.adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(viewWidth)
        bannerView.load(GADRequest())
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, BannerViewControllerWidthDelegate, GADBannerViewDelegate {
        let parent: BannerView

        init(_ parent: BannerView) {
            self.parent = parent
        }

        // MARK: - BannerViewControllerWidthDelegate methods

        func bannerViewController(_ bannerViewController: BannerViewController, didUpdate width: CGFloat) {
            // Pass the viewWidth from Coordinator to BannerView.
            parent.viewWidth = width
        }

        // MARK: - GADBannerViewDelegate methods

        func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
            print("DID RECEIVE AD")
            parent.adHelper.showingAd = true
        }

        func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
            print("DID NOT RECEIVE AD: \(error.localizedDescription)")
            parent.adHelper.showingAd = false
        }

        func bannerViewDidRecordImpression(_ bannerView: GADBannerView) {
            print("\(#function) called")
        }

        func bannerViewWillPresentScreen(_ bannerView: GADBannerView) {
            print("\(#function) called")
        }

        func bannerViewWillDismissScreen(_ bannerView: GADBannerView) {
            print("\(#function) called")
        }

        func bannerViewDidDismissScreen(_ bannerView: GADBannerView) {
            print("\(#function) called")
        }
    }
}
