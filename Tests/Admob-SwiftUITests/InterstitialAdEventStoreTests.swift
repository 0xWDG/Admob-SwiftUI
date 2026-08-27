//
//  InterstitialAdEventStoreTests.swift
//  Admob-SwiftUITests
//

@testable import Admob_SwiftUI
import XCTest

@MainActor
final class InterstitialAdEventStoreTests: XCTestCase {
    func testSendsEventsToEveryObserver() {
        let store = InterstitialAdEventStore()
        var firstObserverCount = 0
        var secondObserverCount = 0

        _ = store.addObserver { _ in firstObserverCount += 1 }
        _ = store.addObserver { _ in secondObserverCount += 1 }

        store.send(.loaded)

        XCTAssertEqual(firstObserverCount, 1)
        XCTAssertEqual(secondObserverCount, 1)
    }

    func testRemovedObserverStopsReceivingEvents() {
        let store = InterstitialAdEventStore()
        var eventCount = 0
        let identifier = store.addObserver { _ in eventCount += 1 }

        store.send(.loaded)
        store.removeObserver(identifier)
        store.send(.dismissed)

        XCTAssertEqual(eventCount, 1)
    }
}
