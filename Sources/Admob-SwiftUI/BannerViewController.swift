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
protocol BannerViewControllerWidthDelegate: AnyObject {
    func bannerViewController(_ bannerViewController: BannerViewController, didUpdate width: CGFloat)
}

public class BannerViewController: UIViewController {
    weak var delegate: BannerViewControllerWidthDelegate?
    private let logger = Logger(
        subsystem: "nl.wesleydegroot.Admob-SwiftUI",
        category: "BannerViewController"
    )

    override public func viewDidAppear(_ animated: Bool) {
        logger.debug("viewDidAppear")
        super.viewDidAppear(animated)

        // Tell the delegate the initial ad width.
        delegate?.bannerViewController(
            self,
            didUpdate: view.frame.inset(by: view.safeAreaInsets).size.width
        )
    }

    override public func viewWillTransition(
        to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator
    ) {
        logger.debug("viewWillTransition")
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
