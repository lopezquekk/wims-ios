//
//  BuildingListViewModel.swift
//  Wims
//
//  Created by Camilo Lopez on 1/11/26.
//

import PersistencyLayer
import SwiftUI

@MainActor
struct BuildingListViewModel: ReducerProtocol {
    struct State: Sendable {
        // Building list state
        var buildings: [BuildingDTO] = []
        var isLoading = false
        var errorMessage: String?

        // Building form state
        var showingAddBuildingDialog = false
        var newBuildingName = ""

        // Building edit state
        var showingEditBuildingSheet = false
        var editBuildingName = ""
    }

    enum Action: Equatable, Sendable {
        // Building actions
        case load
        case addBuilding(name: String)
        case updateBuilding(id: UUID, name: String)
        case deleteBuildings(offsets: IndexSet)

        // UI actions
        case setShowingAddBuildingDialog(Bool)
        case setNewBuildingName(String)
        case setShowingEditBuildingSheet(Bool)
        case setEditBuildingName(String)
    }

    private let buildingRepository: BuildingRepository

    init(buildingRepository: BuildingRepository) {
        self.buildingRepository = buildingRepository
    }

    func reduce(state: inout State, action: Action) async {
        switch action {
        // Building actions
        case .load:
            await load(state: &state)
        case let .addBuilding(name):
            await addBuilding(name: name, state: &state)
        case let .updateBuilding(id, name):
            await updateBuilding(id: id, name: name, state: &state)
        case let .deleteBuildings(offsets):
            await deleteBuildings(at: offsets, state: &state)

        // UI actions
        case let .setShowingAddBuildingDialog(showing):
            state.showingAddBuildingDialog = showing
            if !showing {
                state.newBuildingName = ""
            }
        case let .setNewBuildingName(name):
            state.newBuildingName = name
        case let .setShowingEditBuildingSheet(showing):
            state.showingEditBuildingSheet = showing
        case let .setEditBuildingName(name):
            state.editBuildingName = name
        }
    }

    // MARK: - Building Methods

    private func load(state: inout State) async {
        state.isLoading = true
        state.errorMessage = nil

        do {
            state.buildings = try await buildingRepository.fetchAll()
        } catch {
            state.errorMessage = "Error loading buildings: \(error.localizedDescription)"
            print("Error fetching buildings:", error)
        }

        state.isLoading = false
    }

    private func addBuilding(name: String, state: inout State) async {
        guard !name.isEmpty else {
            state.errorMessage = "Building name cannot be empty"
            return
        }

        state.errorMessage = nil

        do {
            let building = try await buildingRepository.create(name: name)
            state.buildings.append(building)
            state.showingAddBuildingDialog = false
            state.newBuildingName = ""
        } catch {
            state.errorMessage = "Error creating building: \(error.localizedDescription)"
            print("Error creating building:", error)
        }
    }

    private func updateBuilding(id: UUID, name: String, state: inout State) async {
        guard !name.isEmpty else {
            state.errorMessage = "Building name cannot be empty"
            return
        }

        state.errorMessage = nil

        do {
            let updatedBuilding = try await buildingRepository.update(id: id, name: name)
            if let index = state.buildings.firstIndex(where: { $0.id == id }) {
                state.buildings[index] = updatedBuilding
            }
            state.showingEditBuildingSheet = false
        } catch {
            state.errorMessage = "Error updating building: \(error.localizedDescription)"
            print("Error updating building:", error)
        }
    }

    private func deleteBuildings(at offsets: IndexSet, state: inout State) async {
        state.errorMessage = nil

        for index in offsets {
            let building = state.buildings[index]

            do {
                try await buildingRepository.delete(id: building.id)
            } catch {
                state.errorMessage = "Error deleting building: \(error.localizedDescription)"
                print("Error deleting building:", error)
                return
            }
        }

        state.buildings.remove(atOffsets: offsets)
    }
}
