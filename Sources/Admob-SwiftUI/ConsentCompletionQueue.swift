//
//  ConsentCompletionQueue.swift
//  Admob-SwiftUI
//

@MainActor
struct ConsentCompletionQueue {
    typealias Completion = @MainActor @Sendable (Error?) -> Void

    private var completions: [Completion] = []
    private(set) var isGatheringConsent = false

    mutating func enqueue(_ completion: @escaping Completion) -> Bool {
        completions.append(completion)
        guard !isGatheringConsent else { return false }
        isGatheringConsent = true
        return true
    }

    mutating func finish(with error: Error?) {
        isGatheringConsent = false
        let pendingCompletions = completions
        completions.removeAll()
        pendingCompletions.forEach { $0(error) }
    }
}
