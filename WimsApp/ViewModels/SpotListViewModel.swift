//
//  SpotListViewModel.swift
//  Wims
//
//  Created by Camilo Lopez on 1/11/26.
//

import Combine
import PersistencyLayer
import SwiftUI

@MainActor
final class SpotListViewModel: ReducerProtocol {
    struct State {
        var spots: [SpotDTO] = []
        var isLoading = false
        var errorMessage: String?
    }

    enum Action: Equatable {
        case load(room: RoomDTO)
        case addSpot(name: String, room: RoomDTO)
        case updateSpot(id: UUID, name: String)
        case deleteSpots(offsets: IndexSet)
    }

    private let spotRepository: SpotRepository

    init(spotRepository: SpotRepository) {
        self.spotRepository = spotRepository
    }

    func reduce(state: inout State, action: Action) async {
        switch action {
        case let .load(room):
            await load(for: room, state: &state)
        case let .addSpot(name, room):
            await addSpot(name: name, in: room, state: &state)
        case let .updateSpot(id, name):
            await updateSpot(id: id, name: name, state: &state)
        case let .deleteSpots(offsets):
            await deleteSpots(at: offsets, state: &state)
        }
    }

    private func load(for room: RoomDTO, state: inout State) async {
        state.isLoading = true
        state.errorMessage = nil

        do {
            state.spots = try await spotRepository.fetch(in: room)
        } catch {
            state.errorMessage = "Error loading spots: \(error.localizedDescription)"
            print("Error fetching spots:", error)
        }

        state.isLoading = false
    }

    private func addSpot(name: String, in room: RoomDTO, state: inout State) async {
        guard !name.isEmpty else {
            state.errorMessage = "Spot name cannot be empty"
            return
        }

        state.errorMessage = nil

        do {
            let spot = try await spotRepository.create(name: name, in: room)
            state.spots.append(spot)
        } catch {
            state.errorMessage = "Error creating spot: \(error.localizedDescription)"
            print("Error creating spot:", error)
        }
    }

    func updateSpot(id: UUID, name: String, state: inout State) async {
        guard !name.isEmpty else {
            state.errorMessage = "Spot name cannot be empty"
            return
        }

        state.errorMessage = nil

        do {
            let updatedSpot = try await spotRepository.update(id: id, name: name)
            if let index = state.spots.firstIndex(where: { $0.id == id }) {
                state.spots[index] = updatedSpot
            }
        } catch {
            state.errorMessage = "Error updating spot: \(error.localizedDescription)"
            print("Error updating spot:", error)
        }
    }

    func deleteSpots(at offsets: IndexSet, state: inout State) async {
        state.errorMessage = nil

        for index in offsets {
            let spot = state.spots[index]

            do {
                try await spotRepository.delete(id: spot.id)
            } catch {
                state.errorMessage = "Error deleting spot: \(error.localizedDescription)"
                print("Error deleting spot:", error)
                return
            }
        }

        state.spots.remove(atOffsets: offsets)
    }
}
