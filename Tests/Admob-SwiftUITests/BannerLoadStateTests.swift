//
//  BannerLoadStateTests.swift
//  Admob-SwiftUITests
//

@testable import Admob_SwiftUI
import XCTest

final class BannerLoadStateTests: XCTestCase {
    func testLoadsOnlyWhenConfigurationChanges() {
        var state = BannerLoadState()
        let initial = BannerLoadConfiguration(
            adUnitID: "banner",
            size: CGSize(width: 320, height: 50)
        )
        let resized = BannerLoadConfiguration(
            adUnitID: "banner",
            size: CGSize(width: 728, height: 90)
        )

        XCTAssertTrue(state.shouldLoad(initial))
        XCTAssertFalse(state.shouldLoad(initial))
        XCTAssertTrue(state.shouldLoad(resized))
        XCTAssertFalse(state.shouldLoad(resized))
    }

    func testLoadsWhenAdUnitChanges() {
        var state = BannerLoadState()
        let first = BannerLoadConfiguration(
            adUnitID: "first",
            size: CGSize(width: 320, height: 50)
        )
        let second = BannerLoadConfiguration(
            adUnitID: "second",
            size: CGSize(width: 320, height: 50)
        )

        XCTAssertTrue(state.shouldLoad(first))
        XCTAssertTrue(state.shouldLoad(second))
    }
}
