//
//  SpotListViewModel.swift
//  Wims
//
//  Created by Camilo Lopez on 1/11/26.
//

import SwiftUI
import Combine
import PersistencyLayer

@MainActor
final class SpotListViewModel: ObservableObject {

    private let spotRepository: SpotRepository

    @Published var spots: [SpotDTO] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    init(spotRepository: SpotRepository) {
        self.spotRepository = spotRepository
    }

    func load(for room: RoomDTO) async {
        isLoading = true
        errorMessage = nil

        do {
            spots = try await spotRepository.fetch(in: room)
        } catch {
            errorMessage = "Error loading spots: \(error.localizedDescription)"
            print("Error fetching spots:", error)
        }

        isLoading = false
    }

    func addSpot(name: String, in room: RoomDTO) async {
        guard !name.isEmpty else {
            errorMessage = "Spot name cannot be empty"
            return
        }

        errorMessage = nil

        do {
            let spot = try await spotRepository.create(name: name, in: room)
            spots.append(spot)
        } catch {
            errorMessage = "Error creating spot: \(error.localizedDescription)"
            print("Error creating spot:", error)
        }
    }

    func updateSpot(id: UUID, name: String) async {
        guard !name.isEmpty else {
            errorMessage = "Spot name cannot be empty"
            return
        }

        errorMessage = nil

        do {
            let updatedSpot = try await spotRepository.update(id: id, name: name)
            if let index = spots.firstIndex(where: { $0.id == id }) {
                spots[index] = updatedSpot
            }
        } catch {
            errorMessage = "Error updating spot: \(error.localizedDescription)"
            print("Error updating spot:", error)
        }
    }

    func deleteSpots(at offsets: IndexSet) async {
        errorMessage = nil

        for index in offsets {
            let spot = spots[index]

            do {
                try await spotRepository.delete(id: spot.id)
            } catch {
                errorMessage = "Error deleting spot: \(error.localizedDescription)"
                print("Error deleting spot:", error)
                return
            }
        }

        spots.remove(atOffsets: offsets)
    }
}
