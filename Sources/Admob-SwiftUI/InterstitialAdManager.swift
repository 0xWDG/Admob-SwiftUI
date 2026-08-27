//
//  File.swift
//  Admob-SwiftUI
//
//  Created by Wesley de Groot on 24/10/2025.
//

import Foundation
import GoogleMobileAds
import OSLog
import SwiftUI

// MARK: - Interstitial Ad Manager
/// Loads, presents, and reloads a Google Mobile Ads interstitial.
///
/// The manager begins loading during initialization, exposes readiness and
/// loading state for SwiftUI, and automatically loads the next ad after a
/// dismissal or presentation failure. Use ``observeEvents(_:)`` to receive
/// lifecycle events without replacing other observers.
@MainActor
public final class InterstitialAdManager: NSObject, GADFullScreenContentDelegate, ObservableObject {
    private var interstitial: GADInterstitialAd?
    private let adUnitID: String
    private let eventStore = InterstitialAdEventStore()

    /// Whether an interstitial is loaded and ready to present.
    @Published public var isAdReady = false

    /// Whether an interstitial load request is currently in progress.
    @Published public var isLoading = false

    private let logger = Logger(
        subsystem: "nl.wesleydegroot.Admob-SwiftUI",
        category: "InterstitialAdManager"
    )

    /// Creates a manager and immediately starts loading an interstitial.
    ///
    /// - Parameter adUnitID: The Google Mobile Ads interstitial unit identifier.
    public init(adUnitID: String) {
        self.adUnitID = adUnitID
        super.init()
        loadAd()
    }

    /// Loads an interstitial when no other load request is in progress.
    ///
    /// Successful and failed requests emit ``InterstitialAdEvent`` values to all
    /// registered observers. Calling this method while ``isLoading`` is `true`
    /// has no effect.
    public func loadAd() {
        guard !isLoading else { return }
        isLoading = true

        GADInterstitialAd.load(
            withAdUnitID: adUnitID,
            request: GADRequest()
        ) { [weak self] advertisement, error in
            Task { @MainActor in
                guard let self else { return }

                self.isLoading = false

                if let error {
                    self.isAdReady = false
                    self.eventStore.send(.failedToLoad(error))
                    self.logger.error("Failed to load interstitial ad: \(error.localizedDescription)")
                    return
                }

                // Ad successfully loaded
                self.interstitial = advertisement
                self.interstitial?.fullScreenContentDelegate = self
                self.isAdReady = true
                self.eventStore.send(.loaded)
            }
        }
    }

    /// Registers an observer for interstitial ad lifecycle events.
    ///
    /// Observers are invoked on the main actor and coexist with other observers.
    /// Remove the returned identifier using ``removeEventObserver(_:)`` when the
    /// observer's lifetime ends to prevent retaining captured values.
    ///
    /// - Parameter observer: A closure invoked for every lifecycle event.
    /// - Returns: An identifier used to remove this observer.
    @discardableResult
    public func observeEvents(
        _ observer: @MainActor @escaping (InterstitialAdEvent) -> Void
    ) -> UUID {
        eventStore.addObserver(observer)
    }

    /// Removes a previously registered lifecycle event observer.
    ///
    /// Calling this method with an unknown or already removed identifier has no
    /// effect.
    ///
    /// - Parameter identifier: The identifier returned by ``observeEvents(_:)``.
    public func removeEventObserver(_ identifier: UUID) {
        eventStore.removeObserver(identifier)
    }

    /// Presents the loaded interstitial from the application's visible controller.
    ///
    /// When no ad is ready, the method starts a load instead of presenting. When
    /// no active key window can be found, presentation is skipped and the issue
    /// is logged.
    public func showAd() {
        guard var presentingViewController = UIWindowScene.keyWindow?.rootViewController else {
            self.logger.error("No root view controller found to present ads.")
            return
        }

        while let presentedViewController = presentingViewController.presentedViewController {
            presentingViewController = presentedViewController
        }

        if isAdReady, let advertisement = interstitial {
            advertisement.present(fromRootViewController: presentingViewController)
        } else {
            self.logger.debug("Ad not ready, reloading...")
            loadAd()
        }
    }

    /// Handles the start of full-screen interstitial presentation.
    ///
    /// - Parameter ad: The Google full-screen ad being presented.
    nonisolated public func adWillPresentFullScreenContent(
        _ ad: GADFullScreenPresentingAd
        // swiftlint:disable:previous identifier_name
    ) {
        Task { @MainActor in
            self.isAdReady = false
            self.eventStore.send(.presented)
        }
    }

    /// Handles a failure to present full-screen interstitial content.
    ///
    /// The manager emits a failure event and immediately begins loading a
    /// replacement interstitial.
    ///
    /// - Parameters:
    ///   - ad: The Google full-screen ad that failed to present.
    ///   - error: The presentation error reported by Google Mobile Ads.
    nonisolated public func ad(
        _ ad: GADFullScreenPresentingAd,
        // swiftlint:disable:previous identifier_name
        didFailToPresentFullScreenContentWithError error: Error
    ) {
        Task { @MainActor in
            self.isAdReady = false
            self.eventStore.send(.failedToPresent(error))
            self.loadAd()
        }
    }

    /// Handles dismissal of full-screen interstitial content.
    ///
    /// The manager emits a dismissal event and immediately begins loading the
    /// next interstitial.
    ///
    /// - Parameter ad: The Google full-screen ad that was dismissed.
    nonisolated public func adDidDismissFullScreenContent(
        _ ad: GADFullScreenPresentingAd
        // swiftlint:disable:previous identifier_name
    ) {
        Task { @MainActor in
            self.isAdReady = false
            self.eventStore.send(.dismissed)
            self.loadAd()
        }
    }
}

// MARK: - Environment Key
public extension EnvironmentValues {
    /// The interstitial manager installed by ``View/interstitialAd(adUnitID:)``.
    ///
    /// Read this value from a descendant view to call
    /// ``InterstitialAdManager/showAd()`` when an appropriate user action occurs.
    @Entry var interstitialAdManager: InterstitialAdManager?
}

// MARK: - Interstitial Ad Modifier
/// Creates and installs an interstitial manager in the SwiftUI environment.
public struct InterstitialAdViewModifier: ViewModifier {
    @StateObject private var adController: InterstitialAdManager

    /// Creates an interstitial environment modifier.
    ///
    /// The modifier owns a manager that starts loading immediately and remains
    /// alive for the lifetime of the modified view identity.
    ///
    /// - Parameter adUnitID: The Google Mobile Ads interstitial unit identifier.
    public init(adUnitID: String) {
        _adController = StateObject(wrappedValue: InterstitialAdManager(adUnitID: adUnitID))
    }

    /// Installs the owned manager into the modified content's environment.
    ///
    /// - Parameter content: The content receiving the interstitial manager.
    /// - Returns: Content with an interstitial manager environment value.
    public func body(content: Content) -> some View {
        content
            .environment(\.interstitialAdManager, adController)
    }
}

public extension View {
    /// Creates an interstitial manager and installs it in the view environment.
    ///
    /// Descendant views can read `EnvironmentValues.interstitialAdManager` to
    /// present the loaded ad. The manager starts loading when the modifier is
    /// created.
    ///
    /// - Parameter adUnitID: The Google Mobile Ads interstitial unit identifier.
    /// - Returns: A view with an interstitial manager in its environment.
    func interstitialAd(adUnitID: String) -> some View {
        modifier(InterstitialAdViewModifier(adUnitID: adUnitID))
    }
}

// MARK: - UIWindowScene Extension
public extension UIWindowScene {
    /// The key window from the application's first foreground-active scene.
    ///
    /// - Returns: The active key window, or `nil` when no foreground-active
    ///   scene currently owns one.
    static var keyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first(where: { $0.activationState == .foregroundActive })?
            .windows
            .first(where: \.isKeyWindow)
    }
}

// MARK: - Callback Modifier
private struct InterstitialAdEventModifier: ViewModifier {
    let action: @MainActor (InterstitialAdEvent) -> Void
    @Environment(\.interstitialAdManager) var adController
    @State private var observerID: UUID?

    func body(content: Content) -> some View {
        content
            .onAppear {
                guard observerID == nil else { return }
                observerID = adController?.observeEvents(action)
            }
            .onDisappear {
                guard let observerID else { return }
                adController?.removeEventObserver(observerID)
                self.observerID = nil
            }
    }
}

// MARK: - Extensions for Callback Modifiers
public extension View {
    /// Runs an action whenever the environment's interstitial finishes loading.
    ///
    /// The observer is registered when the view appears and removed when it
    /// disappears, so multiple views can observe the same manager safely.
    ///
    /// - Parameter action: The action to perform when an ad becomes ready.
    /// - Returns: A view that observes loaded events.
    func onInterstitialAdLoaded(_ action: @escaping () -> Void) -> some View {
        modifier(InterstitialAdEventModifier { event in
            guard case .loaded = event else { return }
            action()
        })
    }

    /// Runs an action whenever the environment's interstitial fails to load.
    ///
    /// - Parameter action: An action receiving the Google Mobile Ads load error.
    /// - Returns: A view that observes load-failure events.
    func onInterstitialAdFailedToLoad(_ action: @escaping (Error) -> Void) -> some View {
        modifier(InterstitialAdEventModifier { event in
            guard case let .failedToLoad(error) = event else { return }
            action(error)
        })
    }

    /// Runs an action when the environment's interstitial begins presentation.
    ///
    /// - Parameter action: The action to perform when presentation starts.
    /// - Returns: A view that observes presentation events.
    func onInterstitialAdPresented(_ action: @escaping () -> Void) -> some View {
        modifier(InterstitialAdEventModifier { event in
            guard case .presented = event else { return }
            action()
        })
    }

    /// Runs an action when the environment's interstitial fails to present.
    ///
    /// - Parameter action: An action receiving the Google presentation error.
    /// - Returns: A view that observes presentation-failure events.
    func onInterstitialAdFailedToPresent(_ action: @escaping (Error) -> Void) -> some View {
        modifier(InterstitialAdEventModifier { event in
            guard case let .failedToPresent(error) = event else { return }
            action(error)
        })
    }

    /// Runs an action after the environment's interstitial is dismissed.
    ///
    /// - Parameter action: The action to perform after dismissal.
    /// - Returns: A view that observes dismissal events.
    func onInterstitialAdDismissed(_ action: @escaping () -> Void) -> some View {
        modifier(InterstitialAdEventModifier { event in
            guard case .dismissed = event else { return }
            action()
        })
    }
}
