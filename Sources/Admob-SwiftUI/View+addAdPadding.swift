//
//  View+addAdPadding.swift
//  Admob-SwiftUI
//
//  Created by Wesley de Groot on 11/02/2024.
//  https://wesleydegroot.nl
//
//  Usage & Example: https://wesleydegroot.nl/blog/post/Admob-in-SwiftUI

import SwiftUI

extension View {
    /// Adds bottom scroll-content space for an overlaid advertisement.
    ///
    /// On iOS 17 and later, this modifier adds the supplied banner height plus
    /// ten points to the scroll content's bottom margin. Earlier iOS versions
    /// return the view unchanged. Prefer ``AdView`` when possible because its
    /// safe-area inset also works for non-scroll content.
    ///
    /// - Parameter height: The height of the advertisement to keep clear.
    /// - Returns: A view with adjusted scroll-content margins when supported.
    @ViewBuilder public func addAdPadding(height: CGFloat) -> some View {
        if #available(iOS 17.0, *) {
            self
                .contentMargins(
                    .bottom,
                    height + 10,
                    for: .scrollContent
                )
        } else {
            self
        }
    }
}
