//
//  InterstitialAdEvent.swift
//  Admob-SwiftUI
//

/// Describes a lifecycle event emitted by ``InterstitialAdManager``.
///
/// Register an observer using ``InterstitialAdManager/observeEvents(_:)`` or
/// use one of the dedicated SwiftUI callback modifiers.
public enum InterstitialAdEvent {
    /// The interstitial finished loading and can be presented.
    case loaded

    /// The interstitial failed to load.
    ///
    /// The associated error is provided by Google Mobile Ads.
    case failedToLoad(Error)

    /// The interstitial began presenting full-screen content.
    case presented

    /// The loaded interstitial failed to present full-screen content.
    ///
    /// The associated error is provided by Google Mobile Ads.
    case failedToPresent(Error)

    /// The user dismissed the full-screen interstitial content.
    case dismissed
}
