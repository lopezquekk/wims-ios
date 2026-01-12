//
//  RoomListViewModel.swift
//  Wims
//
//  Created by Camilo Lopez on 1/11/26.
//

import SwiftUI
import Combine
import PersistencyLayer

@MainActor
final class RoomListViewModel: ObservableObject {

    private let roomRepository: RoomRepository

    @Published var rooms: [RoomDTO] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    init(roomRepository: RoomRepository) {
        self.roomRepository = roomRepository
    }

    func load(for building: BuildingDTO) async {
        isLoading = true
        errorMessage = nil

        do {
            rooms = try await roomRepository.fetch(in: building)
        } catch {
            errorMessage = "Error loading rooms: \(error.localizedDescription)"
            print("Error fetching rooms:", error)
        }

        isLoading = false
    }

    func addRoom(name: String, in building: BuildingDTO) async {
        guard !name.isEmpty else {
            errorMessage = "Room name cannot be empty"
            return
        }

        errorMessage = nil

        do {
            let room = try await roomRepository.create(name: name, in: building)
            rooms.append(room)
        } catch {
            errorMessage = "Error creating room: \(error.localizedDescription)"
            print("Error creating room:", error)
        }
    }

    func updateRoom(id: UUID, name: String) async {
        guard !name.isEmpty else {
            errorMessage = "Room name cannot be empty"
            return
        }

        errorMessage = nil

        do {
            let updatedRoom = try await roomRepository.update(id: id, name: name)
            if let index = rooms.firstIndex(where: { $0.id == id }) {
                rooms[index] = updatedRoom
            }
        } catch {
            errorMessage = "Error updating room: \(error.localizedDescription)"
            print("Error updating room:", error)
        }
    }

    func deleteRooms(at offsets: IndexSet) async {
        errorMessage = nil

        for index in offsets {
            let room = rooms[index]

            do {
                try await roomRepository.delete(id: room.id)
            } catch {
                errorMessage = "Error deleting room: \(error.localizedDescription)"
                print("Error deleting room:", error)
                return
            }
        }

        rooms.remove(atOffsets: offsets)
    }
}
