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

/// Wraps application content and reserves the bottom safe area for a banner ad.
///
/// Supply an ``AdHelper`` through the environment before creating this view.
/// `AdView` places ``BannerView`` in a bottom safe-area inset so the banner does
/// not overlap the wrapped content.
public struct AdView<Content: View, BackupView: View>: View {
    @EnvironmentObject
    private var adHelper: AdHelper

    @ViewBuilder private let content: Content
    @ViewBuilder private let backupView: BackupView?

    /// Creates an ad-aware content container.
    ///
    /// - Parameters:
    ///   - content: The application content that should remain visible above the
    ///     banner area.
    ///   - backupView: Optional content displayed behind the banner while an ad
    ///     is unavailable or loading.
    public init(
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder backupView: () -> BackupView? = { nil }
    ) {
        self.content = content()
        self.backupView = backupView()
    }

    /// The wrapped content with a bottom banner safe-area inset.
    public var body: some View {
        content
            .environmentObject(adHelper)
            .safeAreaInset(edge: .bottom, spacing: .zero) {
                BannerView {
                    backupView
                }
                .environmentObject(adHelper)
            }
    }
}
