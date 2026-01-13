//
//  SpotListReducer.swift
//  Wims
//
//  Created by Camilo Lopez on 1/11/26.
//

import Combine
import PersistencyLayer
import SwiftUI

@MainActor
struct SpotListReducer: ReducerProtocol {
    struct State: Sendable {
        // Spot list state
        var spots: [SpotDTO] = []
        var isLoading = false
        var errorMessage: String?

        // Spot form state
        var showingAddSpotDialog = false
        var newSpotName = ""

        // Spot detail state
        var showingEditSpotSheet = false
        var editSpotName = ""

        // Box state
        var boxes: [BoxDTO] = []
        var boxesLoading = false
        var boxesError: String?

        // Box form state
        var showingAddBoxDialog = false
        var newBoxLabel = ""
        var newBoxQRCode = ""
    }

    enum Action: Equatable, Sendable {
        // Spot actions
        case load(room: RoomDTO)
        case addSpot(name: String, room: RoomDTO)
        case updateSpot(id: UUID, name: String)
        case deleteSpots(offsets: IndexSet)

        // Spot UI actions
        case setShowingAddSpotDialog(Bool)
        case setNewSpotName(String)
        case setShowingEditSpotSheet(Bool)
        case setEditSpotName(String)

        // Box actions
        case loadBoxes(spot: SpotDTO)
        case addBox(label: String, qrCode: String, spot: SpotDTO)
        case deleteBoxes(offsets: IndexSet)

        // Box UI actions
        case setShowingAddBoxDialog(Bool)
        case setNewBoxLabel(String)
        case setNewBoxQRCode(String)
        case clearBoxForm
    }

    private let spotRepository: SpotRepository
    private let boxRepository: BoxRepository

    init(spotRepository: SpotRepository, boxRepository: BoxRepository) {
        self.spotRepository = spotRepository
        self.boxRepository = boxRepository
    }

    func reduce(state: inout State, action: Action) async {
        switch action {
        // Spot actions
        case let .load(room):
            await load(for: room, state: &state)
        case let .addSpot(name, room):
            await addSpot(name: name, in: room, state: &state)
        case let .updateSpot(id, name):
            await updateSpot(id: id, name: name, state: &state)
        case let .deleteSpots(offsets):
            await deleteSpots(at: offsets, state: &state)

        // Spot UI actions
        case let .setShowingAddSpotDialog(showing):
            state.showingAddSpotDialog = showing
            if !showing {
                state.newSpotName = ""
            }
        case let .setNewSpotName(name):
            state.newSpotName = name
        case let .setShowingEditSpotSheet(showing):
            state.showingEditSpotSheet = showing
        case let .setEditSpotName(name):
            state.editSpotName = name

        // Box actions
        case let .loadBoxes(spot):
            await loadBoxes(for: spot, state: &state)
        case let .addBox(label, qrCode, spot):
            await addBox(label: label, qrCode: qrCode, in: spot, state: &state)
        case let .deleteBoxes(offsets):
            await deleteBoxes(at: offsets, state: &state)

        // Box UI actions
        case let .setShowingAddBoxDialog(showing):
            state.showingAddBoxDialog = showing
            if !showing {
                state.newBoxLabel = ""
                state.newBoxQRCode = ""
            }
        case let .setNewBoxLabel(label):
            state.newBoxLabel = label
        case let .setNewBoxQRCode(qrCode):
            state.newBoxQRCode = qrCode
        case .clearBoxForm:
            state.newBoxLabel = ""
            state.newBoxQRCode = ""
        }
    }

    // MARK: - Spot Methods

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
            state.showingAddSpotDialog = false
            state.newSpotName = ""
        } catch {
            state.errorMessage = "Error creating spot: \(error.localizedDescription)"
            print("Error creating spot:", error)
        }
    }

    private func updateSpot(id: UUID, name: String, state: inout State) async {
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
            state.showingEditSpotSheet = false
        } catch {
            state.errorMessage = "Error updating spot: \(error.localizedDescription)"
            print("Error updating spot:", error)
        }
    }

    private func deleteSpots(at offsets: IndexSet, state: inout State) async {
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

    // MARK: - Box Methods

    private func loadBoxes(for spot: SpotDTO, state: inout State) async {
        state.boxesLoading = true
        state.boxesError = nil

        do {
            state.boxes = try await boxRepository.fetch(in: spot)
        } catch {
            state.boxesError = "Error loading boxes: \(error.localizedDescription)"
            print("Error loading boxes:", error)
        }

        state.boxesLoading = false
    }

    private func addBox(label: String, qrCode: String, in spot: SpotDTO, state: inout State) async {
        guard !label.isEmpty else {
            state.boxesError = "Box label cannot be empty"
            return
        }

        guard !qrCode.isEmpty else {
            state.boxesError = "QR code cannot be empty"
            return
        }

        state.boxesError = nil

        do {
            let newBox = try await boxRepository.create(label: label, qrCode: qrCode, in: spot)
            state.boxes.append(newBox)
            state.showingAddBoxDialog = false
            state.newBoxLabel = ""
            state.newBoxQRCode = ""
        } catch {
            state.boxesError = "Error creating box: \(error.localizedDescription)"
            print("Error creating box:", error)
        }
    }

    private func deleteBoxes(at offsets: IndexSet, state: inout State) async {
        state.boxesError = nil

        for index in offsets {
            let box = state.boxes[index]

            do {
                try await boxRepository.delete(id: box.id)
            } catch {
                state.boxesError = "Error deleting box: \(error.localizedDescription)"
                print("Error deleting box:", error)
                return
            }
        }

        state.boxes.remove(atOffsets: offsets)
    }
}
