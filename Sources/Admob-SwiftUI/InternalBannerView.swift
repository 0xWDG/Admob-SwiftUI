//
//  InternalBannerView.swift
//  Admob-SwiftUI
//
//  Created by Wesley de Groot on 24/10/2025.
//

import Foundation
import SwiftUI
import GoogleMobileAds
import OSLog

// MARK: - Banner View Controller & Delegate
public struct InternalBannerView<BackupView: View>: UIViewControllerRepresentable {
    @EnvironmentObject
    private var adHelper: AdHelper

    private let bannerView = GADBannerView()

    private var backgroundColor: UIColor = .clear
    private var adSize: GADAdSize?
    private var adUnitID: String?

    private var onAdLoaded: (() -> Void)?
    private var onAdFailedToLoad: ((Error) -> Void)?
    private var onAdClicked: (() -> Void)?
    private var onAdClosed: (() -> Void)?
    private var backupView: (() -> BackupView)?

    @State private var viewWidth: CGFloat = .zero
    @State private var bannerDidLoad: Bool = false

    private let logger = Logger(
        subsystem: "nl.wesleydegroot.Admob-SwiftUI",
        category: "InternalBannerView"
    )

    public init(adUnitID: String? = nil, backupView: (() -> BackupView)? = nil) {
        self.adUnitID = adUnitID
        self.backupView = backupView
    }

    public func makeUIViewController(context: Context) -> BannerViewController {
        let bannerViewController = BannerViewController()

        // Configure banner view
        bannerView.adUnitID = adUnitID ?? adHelper.adUnitId
        bannerView.backgroundColor = backgroundColor
        bannerView.rootViewController = bannerViewController
        bannerView.delegate = context.coordinator
        bannerView.translatesAutoresizingMaskIntoConstraints = false

        if let backupView {
            let child = UIHostingController(
                rootView: backupView().frame(width: adHelper.adWidth, height: adHelper.adHeight)
            )
            child.view.translatesAutoresizingMaskIntoConstraints = false
            child.view.backgroundColor = backgroundColor
            bannerViewController.view.addSubview(child.view)
            child.view.topAnchor.constraint(equalTo: bannerViewController.view.topAnchor).isActive = true
            child.view.bottomAnchor.constraint(equalTo: bannerViewController.view.bottomAnchor).isActive = true
            child.view.leftAnchor.constraint(equalTo: bannerViewController.view.leftAnchor).isActive = true
            child.view.rightAnchor.constraint(equalTo: bannerViewController.view.rightAnchor).isActive = true
        }

        bannerViewController.view.addSubview(bannerView)

        NSLayoutConstraint.activate([
            bannerView.bottomAnchor.constraint(equalTo: bannerViewController.view.safeAreaLayoutGuide.bottomAnchor),
            bannerView.leftAnchor.constraint(equalTo: bannerViewController.view.leftAnchor),
            bannerView.rightAnchor.constraint(equalTo: bannerViewController.view.rightAnchor)
        ])

        bannerViewController.delegate = context.coordinator
        return bannerViewController
    }

    public func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        bannerView.isUserInteractionEnabled = bannerDidLoad

        if viewWidth != .zero {
            let adSize = adSize ?? GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(viewWidth)
            bannerView.adSize = adSize
            if uiViewController.preferredContentSize != adSize.size {
                uiViewController.preferredContentSize = adSize.size
            }
        } else {
            bannerView.adSize = GADAdSizeBanner
        }

        bannerView.load(GADRequest())
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    // MARK: - Modifiers for Callbacks
    public func onAdLoaded(_ action: @escaping () -> Void) -> InternalBannerView {
        var copy = self
        copy.onAdLoaded = action
        return copy
    }

    public func onAdFailedToLoad(_ action: @escaping (Error) -> Void) -> InternalBannerView {
        var copy = self
        copy.onAdFailedToLoad = action
        return copy
    }

    public func onAdClicked(_ action: @escaping () -> Void) -> InternalBannerView {
        var copy = self
        copy.onAdClicked = action
        return copy
    }

    public func onAdClosed(_ action: @escaping () -> Void) -> InternalBannerView {
        var copy = self
        copy.onAdClosed = action
        return copy
    }

    public func backgroundColor(_ color: UIColor) -> InternalBannerView {
        var copy = self
        copy.backgroundColor = color
        return copy
    }

    public func adSize(_ size: GADAdSize) -> InternalBannerView {
        var copy = self
        copy.adSize = size
        return copy
    }

    // MARK: - Coordinator
    public class Coordinator: NSObject, BannerViewControllerWidthDelegate, GADBannerViewDelegate {
        public let parent: InternalBannerView

        public init(parent: InternalBannerView) {
            self.parent = parent
        }

        // MARK: - Width Delegate
        public func bannerViewController(_ bannerViewController: BannerViewController, didUpdate width: CGFloat) {
            Task { @MainActor [parent] in
                parent.viewWidth = width
            }
        }

        // MARK: - Banner View Delegate
        public func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
            parent.bannerDidLoad = true
            Task { @MainActor [parent] in
                parent.onAdLoaded?()
            }
        }

        public func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
            parent.bannerDidLoad = false
            Task { @MainActor [parent] in
                parent.onAdFailedToLoad?(error)
            }
        }

        public func bannerViewDidRecordClick(_ bannerView: GADBannerView) {
            Task { @MainActor [parent] in
                parent.onAdClicked?()
            }
        }

        public func bannerViewDidDismissScreen(_ bannerView: GADBannerView) {
            Task { @MainActor [parent] in
                parent.onAdClosed?()
            }
        }
    }
}

#Preview {
    VStack {
        Text("Top content")

        InternalBannerView(adUnitID: "TEST") {
            Button {
                print("Pressed the button")
            } label: {
                Text("Don't like ads?")
            }
        }

        Text("Bottom content")
    }
}
