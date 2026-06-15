//
//  BannerPresentationStateTests.swift
//  Admob-SwiftUITests
//

import Combine
import XCTest
@testable import Admob_SwiftUI

@MainActor
final class BannerPresentationStateTests: XCTestCase {
    func testIdenticalLoadedStateDoesNotInvalidateViews() {
        let helper = AdHelper(adUnitID: "banner")
        var invalidationCount = 0
        let cancellable = helper.objectWillChange.sink {
            invalidationCount += 1
        }

        helper.updateBannerPresentation(
            isShowingAd: true,
            size: CGSize(width: 320, height: 50)
        )
        helper.updateBannerPresentation(
            isShowingAd: true,
            size: CGSize(width: 320, height: 50)
        )

        XCTAssertEqual(invalidationCount, 1)
        withExtendedLifetime(cancellable) {}
    }

    func testChangedBannerSizeInvalidatesViewsOnce() {
        let helper = AdHelper(adUnitID: "banner")
        var invalidationCount = 0
        let cancellable = helper.objectWillChange.sink {
            invalidationCount += 1
        }

        helper.updateBannerPresentation(
            isShowingAd: true,
            size: CGSize(width: 728, height: 90)
        )

        XCTAssertEqual(invalidationCount, 1)
        XCTAssertEqual(helper.adSize, CGSize(width: 728, height: 90))
        withExtendedLifetime(cancellable) {}
    }

    func testIdenticalPublicPropertyAssignmentsDoNotInvalidateViews() {
        let helper = AdHelper(adUnitID: "banner")
        var invalidationCount = 0
        let cancellable = helper.objectWillChange.sink {
            invalidationCount += 1
        }

        helper.adUnitID = "banner"
        helper.adSize = helper.adSize
        helper.showingAd = helper.showingAd

        XCTAssertEqual(invalidationCount, 0)
        withExtendedLifetime(cancellable) {}
    }
}
