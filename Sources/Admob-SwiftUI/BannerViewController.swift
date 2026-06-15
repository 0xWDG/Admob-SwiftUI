//
//  BannerViewController.swift
//  Admob-SwiftUI
//
//  Created by Wesley de Groot on 11/02/2024.
//  https://wesleydegroot.nl
//
//  Usage & Example: https://wesleydegroot.nl/blog/post/Admob-in-SwiftUI

import SwiftUI
import GoogleMobileAds
import OSLog

// Delegate methods for receiving width update messages.
@MainActor
protocol BannerViewControllerWidthDelegate: AnyObject {
    func bannerViewController(_ bannerViewController: BannerViewController, didUpdate width: CGFloat)
}

/// A UIKit container that reports the available banner width to its delegate.
///
/// This controller is primarily an implementation detail of
/// ``InternalBannerView``. It remains public because it is the controller type
/// required by that view's `UIViewControllerRepresentable` conformance.
@MainActor
public final class BannerViewController: UIViewController {
    weak var delegate: BannerViewControllerWidthDelegate?
    private let logger = Logger(
        subsystem: "nl.wesleydegroot.Admob-SwiftUI",
        category: "BannerViewController"
    )

    /// Reports the initial safe-area-adjusted width after the controller appears.
    ///
    /// - Parameter animated: Whether the appearance transition was animated.
    override public func viewDidAppear(_ animated: Bool) {
        logger.debug("viewDidAppear")
        super.viewDidAppear(animated)

        // Tell the delegate the initial ad width.
        delegate?.bannerViewController(
            self,
            didUpdate: view.frame.inset(by: view.safeAreaInsets).size.width
        )
    }

    /// Reports the updated safe-area-adjusted width after a size transition.
    ///
    /// - Parameters:
    ///   - size: The size the controller's view is transitioning to.
    ///   - coordinator: The transition coordinator supplied by UIKit.
    override public func viewWillTransition(
        to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator
    ) {
        logger.debug("viewWillTransition")
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate { _ in
            // do nothing
        } completion: { _ in
            // Notify the delegate of ad width changes.
            self.delegate?.bannerViewController(
                self,
                didUpdate: self.view.frame.inset(
                    by: self.view.safeAreaInsets
                ).size.width
            )
        }
    }
}
