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
    /// Add ad padding
    /// - Parameter height: Height
    @ViewBuilder public func addAdPadding(height: CGFloat) -> some View {
        if #available(iOS 17.0, *) {
            self.contentMargins(
                .bottom,
                height + 10,
                for: .scrollContent
            )
        } else {
            self.padding(
                .bottom,
                height
            )
        }
    }
}
