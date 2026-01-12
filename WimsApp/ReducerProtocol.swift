//
//  ReducerProtocol.swift
//  Wims
//
//  Created by Camilo Lopez on 1/12/26.
//

import SwiftUI

protocol ReducerProtocol {
    associatedtype State: Sendable
    associatedtype Action: Sendable
    nonisolated func reduce(state: inout State, action: Action) async
}

@dynamicMemberLookup
@Observable
final class Reducer<R: ReducerProtocol> {

    @ObservationIgnored private let reducer: R
    private(set) var state: R.State

    init(reducer: R, initialState: R.State) {
        self.reducer = reducer
        self.state = initialState
    }

    func send(action: R.Action) async {
        // Make a local copy since we can't pass properties as inout to async functions
        var localState = state
        // Call reduce with the local copy
        await reducer.reduce(state: &localState, action: action)
        // Update the actual state after reduce completes
        state = localState
    }

    // Dynamic member lookup to access state properties directly
    subscript<T>(dynamicMember keyPath: KeyPath<R.State, T>) -> T {
        state[keyPath: keyPath]
    }
}
