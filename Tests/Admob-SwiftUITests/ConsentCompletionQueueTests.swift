//
//  ConsentCompletionQueueTests.swift
//  Admob-SwiftUITests
//

import XCTest
@testable import Admob_SwiftUI

@MainActor
final class ConsentCompletionQueueTests: XCTestCase {
    func testCoalescesRequestsAndCompletesEveryObserver() {
        var queue = ConsentCompletionQueue()
        var completionCount = 0

        XCTAssertTrue(queue.enqueue { _ in completionCount += 1 })
        XCTAssertFalse(queue.enqueue { _ in completionCount += 1 })
        XCTAssertTrue(queue.isGatheringConsent)

        queue.finish(with: nil)

        XCTAssertEqual(completionCount, 2)
        XCTAssertFalse(queue.isGatheringConsent)
    }

    func testStartsNewRequestAfterFinishing() {
        var queue = ConsentCompletionQueue()

        XCTAssertTrue(queue.enqueue { _ in })
        queue.finish(with: nil)
        XCTAssertTrue(queue.enqueue { _ in })
    }

    func testForwardsErrorToEveryObserver() {
        var queue = ConsentCompletionQueue()
        let expectedError = NSError(domain: "Consent", code: 1)
        var receivedErrors: [NSError] = []

        _ = queue.enqueue { error in
            if let error = error as? NSError {
                receivedErrors.append(error)
            }
        }
        _ = queue.enqueue { error in
            if let error = error as? NSError {
                receivedErrors.append(error)
            }
        }

        queue.finish(with: expectedError)

        XCTAssertEqual(receivedErrors, [expectedError, expectedError])
    }
}
