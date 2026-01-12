//
//  BuildingListViewModel.swift
//  Wims
//
//  Created by Camilo Lopez on 1/11/26.
//

import PersistencyLayer
import SwiftUI

@MainActor
@Observable
final class BuildingListViewModel {
    private let buildingRepository: BuildingRepository

    var buildings: [BuildingDTO] = []
    var isLoading = false
    var errorMessage: String?

    init(buildingRepository: BuildingRepository) {
        self.buildingRepository = buildingRepository
    }

    func load() async {
        isLoading = true
        errorMessage = nil

        do {
            buildings = try await buildingRepository.fetchAll()
        } catch {
            errorMessage = "Error loading buildings: \(error.localizedDescription)"
            print("Error fetching buildings:", error)
        }

        isLoading = false
    }

    func addBuilding(name: String) async {
        guard !name.isEmpty else {
            errorMessage = "Building name cannot be empty"
            return
        }

        errorMessage = nil

        do {
            let building = try await buildingRepository.create(name: name)
            buildings.append(building)
        } catch {
            errorMessage = "Error creating building: \(error.localizedDescription)"
            print("Error creating building:", error)
        }
    }

    func updateBuilding(id: UUID, name: String) async {
        guard !name.isEmpty else {
            errorMessage = "Building name cannot be empty"
            return
        }

        errorMessage = nil

        do {
            let updatedBuilding = try await buildingRepository.update(id: id, name: name)
            if let index = buildings.firstIndex(where: { $0.id == id }) {
                buildings[index] = updatedBuilding
            }
        } catch {
            errorMessage = "Error updating building: \(error.localizedDescription)"
            print("Error updating building:", error)
        }
    }

    func deleteBuildings(at offsets: IndexSet) async {
        errorMessage = nil

        for index in offsets {
            let building = buildings[index]

            do {
                try await buildingRepository.delete(id: building.id)
            } catch {
                errorMessage = "Error deleting building: \(error.localizedDescription)"
                print("Error deleting building:", error)
                return
            }
        }

        buildings.remove(atOffsets: offsets)
    }
}
