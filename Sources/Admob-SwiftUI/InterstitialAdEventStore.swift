//
//  InterstitialAdEventStore.swift
//  Admob-SwiftUI
//

import Foundation

@MainActor
final class InterstitialAdEventStore {
    typealias Observer = @MainActor (InterstitialAdEvent) -> Void

    private var observers: [UUID: Observer] = [:]

    func addObserver(_ observer: @escaping Observer) -> UUID {
        let identifier = UUID()
        observers[identifier] = observer
        return identifier
    }

    func removeObserver(_ identifier: UUID) {
        observers[identifier] = nil
    }

    func send(_ event: InterstitialAdEvent) {
        Array(observers.values).forEach { $0(event) }
    }
}
