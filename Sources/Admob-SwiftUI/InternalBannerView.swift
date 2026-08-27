//
//  InternalBannerView.swift
//  Admob-SwiftUI
//
//  Created by Wesley de Groot on 24/10/2025.
//

import GoogleMobileAds
import SwiftUI

// MARK: - Banner View Controller & Delegate
/// A low-level SwiftUI wrapper around `GADBannerView`.
///
/// Use ``BannerView`` for the standard consent-aware banner experience.
/// `InternalBannerView` is available when callers need to override the ad unit,
/// ad size, background color, or receive Google banner delegate callbacks.
public struct InternalBannerView<BackupView: View>: UIViewControllerRepresentable {
    @EnvironmentObject
    private var adHelper: AdHelper

    private var backgroundColor: UIColor = .clear
    private var adSize: GADAdSize?
    private var adUnitID: String?

    private var onAdLoaded: (() -> Void)?
    private var onAdFailedToLoad: ((Error) -> Void)?
    private var onAdClicked: (() -> Void)?
    private var onAdClosed: (() -> Void)?
    private let backupView: BackupView?

    /// Creates a configurable Google Mobile Ads banner wrapper.
    ///
    /// - Parameters:
    ///   - adUnitID: An optional ad unit override. When omitted, the value from
    ///     the environment's ``AdHelper/adUnitID`` is used.
    ///   - backupView: Optional SwiftUI content displayed behind the banner.
    public init(
        adUnitID: String? = nil,
        @ViewBuilder backupView: () -> BackupView? = { nil }
    ) {
        self.adUnitID = adUnitID
        self.backupView = backupView()
    }

    /// Creates and configures the UIKit controller that hosts the banner.
    ///
    /// SwiftUI calls this method once for a representable controller identity.
    /// The coordinator retains the `GADBannerView` so subsequent SwiftUI updates
    /// reuse the same Google banner instance.
    ///
    /// - Parameter context: Context containing the representable coordinator.
    /// - Returns: A configured banner container controller.
    public func makeUIViewController(context: Context) -> BannerViewController {
        let bannerViewController = BannerViewController()
        let bannerView = context.coordinator.bannerView

        // Configure banner view
        bannerView.adUnitID = adUnitID ?? adHelper.adUnitID
        bannerView.backgroundColor = backgroundColor
        bannerView.rootViewController = bannerViewController
        bannerView.delegate = context.coordinator
        bannerView.translatesAutoresizingMaskIntoConstraints = false

        if let backupView {
            let child = UIHostingController(rootView: backupView)
            child.view.translatesAutoresizingMaskIntoConstraints = false
            child.view.backgroundColor = backgroundColor
            bannerViewController.addChild(child)
            bannerViewController.view.addSubview(child.view)
            NSLayoutConstraint.activate([
                child.view.topAnchor.constraint(equalTo: bannerViewController.view.topAnchor),
                child.view.bottomAnchor.constraint(equalTo: bannerViewController.view.bottomAnchor),
                child.view.leadingAnchor.constraint(equalTo: bannerViewController.view.leadingAnchor),
                child.view.trailingAnchor.constraint(equalTo: bannerViewController.view.trailingAnchor)
            ])
            child.didMove(toParent: bannerViewController)
            context.coordinator.backupViewController = child
        }

        bannerViewController.view.addSubview(bannerView)

        NSLayoutConstraint.activate([
            bannerView.bottomAnchor.constraint(equalTo: bannerViewController.view.safeAreaLayoutGuide.bottomAnchor),
            bannerView.centerXAnchor.constraint(equalTo: bannerViewController.view.centerXAnchor)
        ])

        bannerViewController.delegate = context.coordinator
        return bannerViewController
    }

    /// Applies changed SwiftUI configuration to the existing banner controller.
    ///
    /// A new ad request is sent only when the effective ad unit or banner size
    /// changes. Ordinary SwiftUI body updates do not reload an already loaded ad.
    ///
    /// - Parameters:
    ///   - uiViewController: The existing banner container controller.
    ///   - context: Context containing the current coordinator.
    public func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        context.coordinator.parent = self
        context.coordinator.updateBanner(in: uiViewController)
    }

    /// Creates the coordinator that owns the Google banner and receives callbacks.
    ///
    /// - Returns: A coordinator associated with this representable.
    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    // MARK: - Modifiers for Callbacks
    /// Registers an action invoked after the banner successfully receives an ad.
    ///
    /// - Parameter action: The action to run on the main actor after loading.
    /// - Returns: A copy of the banner configured with the callback.
    public func onAdLoaded(_ action: @escaping () -> Void) -> InternalBannerView {
        var copy = self
        copy.onAdLoaded = action
        return copy
    }

    /// Registers an action invoked when the banner fails to receive an ad.
    ///
    /// - Parameter action: The action that receives the Google Mobile Ads error.
    /// - Returns: A copy of the banner configured with the callback.
    public func onAdFailedToLoad(_ action: @escaping (Error) -> Void) -> InternalBannerView {
        var copy = self
        copy.onAdFailedToLoad = action
        return copy
    }

    /// Registers an action invoked after the user records a banner click.
    ///
    /// - Parameter action: The action to run after the click is recorded.
    /// - Returns: A copy of the banner configured with the callback.
    public func onAdClicked(_ action: @escaping () -> Void) -> InternalBannerView {
        var copy = self
        copy.onAdClicked = action
        return copy
    }

    /// Registers an action invoked after full-screen banner content is dismissed.
    ///
    /// - Parameter action: The action to run after dismissal.
    /// - Returns: A copy of the banner configured with the callback.
    public func onAdClosed(_ action: @escaping () -> Void) -> InternalBannerView {
        var copy = self
        copy.onAdClosed = action
        return copy
    }

    /// Sets the background color used by the banner and optional fallback view.
    ///
    /// - Parameter color: The UIKit color to display behind banner content.
    /// - Returns: A copy of the banner configured with the background color.
    public func backgroundColor(_ color: UIColor) -> InternalBannerView {
        var copy = self
        copy.backgroundColor = color
        return copy
    }

    /// Uses a fixed Google Mobile Ads size instead of an adaptive banner size.
    ///
    /// - Parameter size: The Google banner size to request.
    /// - Returns: A copy of the banner configured with the fixed size.
    public func adSize(_ size: GADAdSize) -> InternalBannerView {
        var copy = self
        copy.adSize = size
        return copy
    }

    // MARK: - Coordinator
    /// Owns the UIKit banner instance and bridges Google delegate callbacks.
    ///
    /// SwiftUI creates one coordinator for each representable controller
    /// identity. The coordinator deduplicates load requests and updates shared
    /// banner presentation state only when values actually change.
    @MainActor
    public class Coordinator: NSObject, BannerViewControllerWidthDelegate, @preconcurrency GADBannerViewDelegate {
        var parent: InternalBannerView
        let bannerView = GADBannerView()
        var backupViewController: UIViewController?
        private var viewWidth: CGFloat = .zero
        private var loadState = BannerLoadState()

        /// Creates a coordinator for an internal banner view.
        ///
        /// - Parameter parent: The current representable configuration.
        public init(parent: InternalBannerView) {
            self.parent = parent
        }

        func updateBanner(in viewController: BannerViewController) {
            let unitID = parent.adUnitID ?? parent.adHelper.adUnitID
            let size = parent.adSize ?? adaptiveAdSize
            let configuration = BannerLoadConfiguration(adUnitID: unitID, size: size.size)

            bannerView.backgroundColor = parent.backgroundColor
            bannerView.adUnitID = unitID
            bannerView.adSize = size
            viewController.preferredContentSize = size.size

            guard loadState.shouldLoad(configuration) else { return }
            bannerView.load(GADRequest())
        }

        private var adaptiveAdSize: GADAdSize {
            guard viewWidth > .zero else { return GADAdSizeBanner }
            return GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(viewWidth)
        }

        // MARK: - Width Delegate
        /// Responds to changes in the width available to the adaptive banner.
        ///
        /// A new request is made only when the resulting effective banner
        /// configuration differs from the last requested configuration.
        ///
        /// - Parameters:
        ///   - bannerViewController: The controller reporting its available width.
        ///   - width: The safe-area-adjusted width available for the banner.
        public func bannerViewController(_ bannerViewController: BannerViewController, didUpdate width: CGFloat) {
            guard viewWidth != width else { return }
            viewWidth = width
            updateBanner(in: bannerViewController)
        }

        // MARK: - Banner View Delegate
        /// Handles a successfully loaded Google banner.
        ///
        /// The shared helper is invalidated only when the loaded presentation
        /// state actually changed, preventing repeated successful refreshes from
        /// causing unnecessary SwiftUI renders.
        ///
        /// - Parameter bannerView: The banner that received an ad.
        public func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
            bannerView.isUserInteractionEnabled = true
            Task { @MainActor [parent] in
                parent.adHelper.updateBannerPresentation(
                    isShowingAd: true,
                    size: bannerView.adSize.size
                )
                parent.onAdLoaded?()
            }
        }

        /// Handles a Google banner load failure.
        ///
        /// - Parameters:
        ///   - bannerView: The banner that failed to receive an ad.
        ///   - error: The error reported by Google Mobile Ads.
        public func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
            bannerView.isUserInteractionEnabled = false
            Task { @MainActor [parent] in
                parent.adHelper.updateBannerPresentation(isShowingAd: false)
                parent.onAdFailedToLoad?(error)
            }
        }

        /// Handles a recorded click on the Google banner.
        ///
        /// - Parameter bannerView: The banner that recorded the click.
        public func bannerViewDidRecordClick(_ bannerView: GADBannerView) {
            Task { @MainActor [parent] in
                parent.onAdClicked?()
            }
        }

        /// Handles dismissal of full-screen content opened by the banner.
        ///
        /// - Parameter bannerView: The banner whose content was dismissed.
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
