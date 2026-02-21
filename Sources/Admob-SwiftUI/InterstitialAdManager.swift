//
//  File.swift
//  Admob-SwiftUI
//
//  Created by Wesley de Groot on 24/10/2025.
//

import Foundation
import SwiftUI
import GoogleMobileAds
import OSLog

// MARK: - Interstitial Ad Manager
@MainActor
public class InterstitialAdManager: NSObject, GADFullScreenContentDelegate, ObservableObject {
    @EnvironmentObject
    private var adHelper: AdHelper

    private var interstitial: GADInterstitialAd?
    private let adUnitID: String?

    @Published public var isAdReady = false
    @Published public var isLoading = false

    // Callbacks
    public var onAdLoaded: (() -> Void)?
    public var onAdFailedToLoad: ((Error) -> Void)?
    public var onAdPresented: (() -> Void)?
    public var onAdFailedToPresent: ((Error) -> Void)?
    public var onAdDismissed: (() -> Void)?

    private let logger = Logger(
        subsystem: "nl.wesleydegroot.Admob-SwiftUI",
        category: "InterstitialAdManager"
    )

    public init(adUnitID: String? = nil) {
        self.adUnitID = adUnitID
        super.init()
        loadAd()
    }

    // MARK: - Load Ad
    public func loadAd() {
        guard !isLoading else { return }
        isLoading = true

        GADInterstitialAd.load(
            withAdUnitID: adUnitID ?? adHelper.adUnitId,
            request: GADRequest()
        ) { [weak self] advertisement, error in
            Task { @MainActor in
                guard let self = self else { return }

                self.isLoading = false

                if let error = error {
                    self.isAdReady = false
                    self.onAdFailedToLoad?(error)
                    self.logger.error("Failed to load interstitial ad: \(error.localizedDescription)")
                    return
                }

                // Ad successfully loaded
                self.interstitial = advertisement
                self.interstitial?.fullScreenContentDelegate = self
                self.isAdReady = true
                self.onAdLoaded?()
            }
        }
    }

    // MARK: - Show Ad
    public func showAd() {
        guard let rootViewController = UIWindowScene.keyWindow?.rootViewController else {
            self.logger.error("No root view controller found to present ads.")
            return
        }
        if isAdReady, let advertisement = interstitial {
            advertisement.present(fromRootViewController: rootViewController)
        } else {
            self.logger.debug("Ad not ready, reloading...")
            loadAd()
        }
    }

    // MARK: - GADFullScreenContentDelegate
    nonisolated public func adWillPresentFullScreenContent(
        _ ad: GADFullScreenPresentingAd
        // swiftlint:disable:previous identifier_name
    ) {
        Task { @MainActor in
            self.isAdReady = false
            self.onAdPresented?()
        }
    }

    /// ad failed to present
    /// 
    /// - Parameters:
    ///   - ad: The ad that failed to present.
    ///   - error: The error that occurred.
    nonisolated public func ad(
        _ ad: GADFullScreenPresentingAd,
        // swiftlint:disable:previous identifier_name
        didFailToPresentFullScreenContentWithError error: Error
    ) {
        Task { @MainActor in
            self.isAdReady = false
            self.onAdFailedToPresent?(error)
            self.loadAd()
        }
    }

    nonisolated public func adDidDismissFullScreenContent(
        _ ad: GADFullScreenPresentingAd
        // swiftlint:disable:previous identifier_name
    ) {
        Task { @MainActor in
            self.isAdReady = false
            self.onAdDismissed?()
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
            self.loadAd()
        }
    }
}

// MARK: - Environment Key
public struct InterstitialAdManagerKey: EnvironmentKey {
    public static let defaultValue: InterstitialAdManager? = nil
}

public extension EnvironmentValues {
    /// Interstitial Ad Manager
    var interstitialAdManager: InterstitialAdManager? {
        get { self[InterstitialAdManagerKey.self] }
        set { self[InterstitialAdManagerKey.self] = newValue }
    }
}

// MARK: - Interstitial Ad Modifier
public struct InterstitialAdViewModifier: ViewModifier {
    @StateObject private var adController: InterstitialAdManager

    public init(adUnitID: String) {
        _adController = StateObject(wrappedValue: InterstitialAdManager(adUnitID: adUnitID))
    }

    public func body(content: Content) -> some View {
        content
            .environment(\.interstitialAdManager, adController)
    }
}

public extension View {
    /// Attach an interstitial ad to the view.
    /// 
    /// - Parameter adUnitID: The Ad unit identifier.
    func interstitialAd(adUnitID: String) -> some View {
        modifier(InterstitialAdViewModifier(adUnitID: adUnitID))
    }
}

// MARK: - UIWindowScene Extension
public extension UIWindowScene {
    /// Get the key window of the application
    static var keyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first(where: { $0.activationState == .foregroundActive })?
            .windows
            .first(where: \.isKeyWindow)
    }
}

// MARK: - Callback Modifiers
public struct InterstitialAdLoadedModifier: ViewModifier {
    let action: () -> Void
    @Environment(\.interstitialAdManager) var adController

    public func body(content: Content) -> some View {
        content
            .onAppear {
                adController?.onAdLoaded = action
            }
    }
}

public struct InterstitialAdFailedToLoadModifier: ViewModifier {
    let action: (Error) -> Void
    @Environment(\.interstitialAdManager) var adController

    public func body(content: Content) -> some View {
        content
            .onAppear {
                adController?.onAdFailedToLoad = action
            }
    }
}

public struct InterstitialAdPresentedModifier: ViewModifier {
    let action: () -> Void
    @Environment(\.interstitialAdManager) var adController

    public func body(content: Content) -> some View {
        content
            .onAppear {
                adController?.onAdPresented = action
            }
    }
}

public struct InterstitialAdFailedToPresentModifier: ViewModifier {
    let action: (Error) -> Void
    @Environment(\.interstitialAdManager) var adController

    public func body(content: Content) -> some View {
        content
            .onAppear {
                adController?.onAdFailedToPresent = action
            }
    }
}

public struct InterstitialAdDismissedModifier: ViewModifier {
    let action: () -> Void
    @Environment(\.interstitialAdManager) var adController

    public func body(content: Content) -> some View {
        content
            .onAppear {
                adController?.onAdDismissed = action
            }
    }
}

// MARK: - Extensions for Callback Modifiers
public extension View {
    /// Callback when interstitial ad is loaded
    /// 
    /// - Parameter action: The action to perform when the ad is loaded.
    func onInterstitialAdLoaded(_ action: @escaping () -> Void) -> some View {
        modifier(InterstitialAdLoadedModifier(action: action))
    }

    /// Callback when interstitial ad fails to load
    /// 
    /// - Parameter action: The action to perform when the ad fails to load.
    func onInterstitialAdFailedToLoad(_ action: @escaping (Error) -> Void) -> some View {
        modifier(InterstitialAdFailedToLoadModifier(action: action))
    }

    /// Callback when interstitial ad is presented
    /// 
    /// - Parameter action: The action to perform when the ad is presented.
    func onInterstitialAdPresented(_ action: @escaping () -> Void) -> some View {
        modifier(InterstitialAdPresentedModifier(action: action))
    }

    /// Callback when interstitial ad fails to present
    /// 
    /// - Parameter action: The action to perform when the ad fails to present.
    func onInterstitialAdFailedToPresent(_ action: @escaping (Error) -> Void) -> some View {
        modifier(InterstitialAdFailedToPresentModifier(action: action))
    }

    /// Callback when interstitial ad is dismissed
    /// 
    /// - Parameter action: The action to perform when the ad is dismissed.
    func onInterstitialAdDismissed(_ action: @escaping () -> Void) -> some View {
        modifier(InterstitialAdDismissedModifier(action: action))
    }
}
