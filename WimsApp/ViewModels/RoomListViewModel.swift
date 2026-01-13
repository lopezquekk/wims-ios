//
//  RoomListViewModel.swift
//  Wims
//
//  Created by Camilo Lopez on 1/11/26.
//

import Combine
import PersistencyLayer
import SwiftUI

@MainActor
struct RoomListViewModel: ReducerProtocol {
    struct State: Sendable {
        // Room list state
        var rooms: [RoomDTO] = []
        var isLoading = false
        var errorMessage: String?

        // Room form state
        var showingAddRoomDialog = false
        var newRoomName = ""

        // Room edit state
        var showingEditRoomSheet = false
        var editRoomName = ""
    }

    enum Action: Equatable, Sendable {
        // Room actions
        case load(building: BuildingDTO)
        case addRoom(name: String, building: BuildingDTO)
        case updateRoom(id: UUID, name: String)
        case deleteRooms(offsets: IndexSet)

        // UI actions
        case setShowingAddRoomDialog(Bool)
        case setNewRoomName(String)
        case setShowingEditRoomSheet(Bool)
        case setEditRoomName(String)
    }

    private let roomRepository: RoomRepository

    init(roomRepository: RoomRepository) {
        self.roomRepository = roomRepository
    }

    func reduce(state: inout State, action: Action) async {
        switch action {
        // Room actions
        case let .load(building):
            await load(for: building, state: &state)
        case let .addRoom(name, building):
            await addRoom(name: name, in: building, state: &state)
        case let .updateRoom(id, name):
            await updateRoom(id: id, name: name, state: &state)
        case let .deleteRooms(offsets):
            await deleteRooms(at: offsets, state: &state)

        // UI actions
        case let .setShowingAddRoomDialog(showing):
            state.showingAddRoomDialog = showing
            if !showing {
                state.newRoomName = ""
            }
        case let .setNewRoomName(name):
            state.newRoomName = name
        case let .setShowingEditRoomSheet(showing):
            state.showingEditRoomSheet = showing
        case let .setEditRoomName(name):
            state.editRoomName = name
        }
    }

    // MARK: - Room Methods

    private func load(for building: BuildingDTO, state: inout State) async {
        state.isLoading = true
        state.errorMessage = nil

        do {
            state.rooms = try await roomRepository.fetch(in: building)
        } catch {
            state.errorMessage = "Error loading rooms: \(error.localizedDescription)"
            print("Error fetching rooms:", error)
        }

        state.isLoading = false
    }

    private func addRoom(name: String, in building: BuildingDTO, state: inout State) async {
        guard !name.isEmpty else {
            state.errorMessage = "Room name cannot be empty"
            return
        }

        state.errorMessage = nil

        do {
            let room = try await roomRepository.create(name: name, in: building)
            state.rooms.append(room)
            state.showingAddRoomDialog = false
            state.newRoomName = ""
        } catch {
            state.errorMessage = "Error creating room: \(error.localizedDescription)"
            print("Error creating room:", error)
        }
    }

    private func updateRoom(id: UUID, name: String, state: inout State) async {
        guard !name.isEmpty else {
            state.errorMessage = "Room name cannot be empty"
            return
        }

        state.errorMessage = nil

        do {
            let updatedRoom = try await roomRepository.update(id: id, name: name)
            if let index = state.rooms.firstIndex(where: { $0.id == id }) {
                state.rooms[index] = updatedRoom
            }
            state.showingEditRoomSheet = false
        } catch {
            state.errorMessage = "Error updating room: \(error.localizedDescription)"
            print("Error updating room:", error)
        }
    }

    private func deleteRooms(at offsets: IndexSet, state: inout State) async {
        state.errorMessage = nil

        for index in offsets {
            let room = state.rooms[index]

            do {
                try await roomRepository.delete(id: room.id)
            } catch {
                state.errorMessage = "Error deleting room: \(error.localizedDescription)"
                print("Error deleting room:", error)
                return
            }
        }

        state.rooms.remove(atOffsets: offsets)
    }
}
