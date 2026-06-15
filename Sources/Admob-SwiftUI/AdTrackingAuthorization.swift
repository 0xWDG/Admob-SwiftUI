//
//  AdTrackingAuthorization.swift
//  Admob-SwiftUI
//

import AppTrackingTransparency

/// Provides explicit access to App Tracking Transparency authorization.
///
/// Ad views in this package never trigger the system authorization prompt
/// automatically. The host app should explain why tracking is requested, then
/// call ``request()`` at an appropriate point in its own user experience.
public enum AdTrackingAuthorization {
    /// The application's current App Tracking Transparency authorization status.
    ///
    /// Reading this property does not present a system prompt or otherwise ask
    /// the user for permission.
    public static var status: ATTrackingManager.AuthorizationStatus {
        ATTrackingManager.trackingAuthorizationStatus
    }

    /// Requests App Tracking Transparency authorization from the user.
    ///
    /// The system prompt is shown only when the current status is
    /// `ATTrackingManager.AuthorizationStatus.notDetermined`. Call this method
    /// after presenting any explanatory UI required by the host app.
    ///
    /// - Returns: The authorization status selected by the user, or the
    ///   application's existing status when no prompt is shown.
    @MainActor
    public static func request() async -> ATTrackingManager.AuthorizationStatus {
        await ATTrackingManager.requestTrackingAuthorization()
    }
}
