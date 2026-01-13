//
//  BoxListReducer.swift
//  Wims
//
//  Created by Camilo Lopez on 1/11/26.
//

import Combine
import PersistencyLayer
import SwiftUI

@MainActor
struct BoxListReducer: ReducerProtocol {
    struct State: Sendable {
        // Box list state
        var boxes: [BoxDTO] = []
        var isLoading = false
        var errorMessage: String?
        var searchText = ""

        // QR Scanner state
        var showingQRScanner = false
        var qrCodeInput = ""

        // Computed property for filtered boxes
        var filteredBoxes: [BoxDTO] {
            if searchText.isEmpty {
                return boxes
            }
            return boxes.filter { box in
                box.label.localizedCaseInsensitiveContains(searchText) ||
                box.qrCode.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    enum Action: Equatable, Sendable {
        // Box actions
        case loadAll
        case load(spot: SpotDTO)
        case searchByQR(qrCode: String)
        case addBox(label: String, qrCode: String, spot: SpotDTO)
        case updateBox(id: UUID, label: String, qrCode: String)
        case deleteBoxes(offsets: IndexSet)

        // UI actions
        case setSearchText(String)
        case setShowingQRScanner(Bool)
        case setQRCodeInput(String)
    }

    private let boxRepository: BoxRepository

    init(boxRepository: BoxRepository) {
        self.boxRepository = boxRepository
    }

    func reduce(state: inout State, action: Action) async {
        switch action {
        // Box actions
        case .loadAll:
            await loadAll(state: &state)
        case let .load(spot):
            await load(for: spot, state: &state)
        case let .searchByQR(qrCode):
            await searchBox(byQRCode: qrCode, state: &state)
        case let .addBox(label, qrCode, spot):
            await addBox(label: label, qrCode: qrCode, in: spot, state: &state)
        case let .updateBox(id, label, qrCode):
            await updateBox(id: id, label: label, qrCode: qrCode, state: &state)
        case let .deleteBoxes(offsets):
            await deleteBoxes(at: offsets, state: &state)

        // UI actions
        case let .setSearchText(text):
            state.searchText = text
        case let .setShowingQRScanner(showing):
            state.showingQRScanner = showing
            if !showing {
                state.qrCodeInput = ""
            }
        case let .setQRCodeInput(input):
            state.qrCodeInput = input
        }
    }

    // MARK: - Box Methods

    private func loadAll(state: inout State) async {
        state.isLoading = true
        state.errorMessage = nil

        do {
            state.boxes = try await boxRepository.fetchAll()
        } catch {
            state.errorMessage = "Error loading boxes: \(error.localizedDescription)"
            print("Error loading boxes:", error)
        }

        state.isLoading = false
    }

    private func load(for spot: SpotDTO, state: inout State) async {
        state.isLoading = true
        state.errorMessage = nil

        do {
            state.boxes = try await boxRepository.fetch(in: spot)
        } catch {
            state.errorMessage = "Error loading boxes: \(error.localizedDescription)"
            print("Error loading boxes:", error)
        }

        state.isLoading = false
    }

    private func searchBox(byQRCode qrCode: String, state: inout State) async {
        guard !qrCode.isEmpty else {
            state.errorMessage = "QR Code cannot be empty"
            return
        }

        state.isLoading = true
        state.errorMessage = nil

        do {
            if let box = try await boxRepository.fetch(byQRCode: qrCode) {
                state.boxes = [box]
                state.showingQRScanner = false
                state.qrCodeInput = ""
            } else {
                state.errorMessage = "No box found with QR code: \(qrCode)"
                state.boxes = []
            }
        } catch {
            state.errorMessage = "Error searching box: \(error.localizedDescription)"
            print("Error searching box:", error)
        }

        state.isLoading = false
    }

    private func addBox(label: String, qrCode: String, in spot: SpotDTO, state: inout State) async {
        guard !label.isEmpty else {
            state.errorMessage = "Box label cannot be empty"
            return
        }

        guard !qrCode.isEmpty else {
            state.errorMessage = "QR code cannot be empty"
            return
        }

        state.errorMessage = nil

        do {
            let newBox = try await boxRepository.create(label: label, qrCode: qrCode, in: spot)
            state.boxes.append(newBox)
        } catch {
            state.errorMessage = "Error creating box: \(error.localizedDescription)"
            print("Error creating box:", error)
        }
    }

    private func updateBox(id: UUID, label: String, qrCode: String, state: inout State) async {
        guard !label.isEmpty else {
            state.errorMessage = "Box label cannot be empty"
            return
        }

        guard !qrCode.isEmpty else {
            state.errorMessage = "QR code cannot be empty"
            return
        }

        state.errorMessage = nil

        do {
            let updatedBox = try await boxRepository.update(id: id, label: label, qrCode: qrCode)
            if let index = state.boxes.firstIndex(where: { $0.id == id }) {
                state.boxes[index] = updatedBox
            }
        } catch {
            state.errorMessage = "Error updating box: \(error.localizedDescription)"
            print("Error updating box:", error)
        }
    }

    private func deleteBoxes(at offsets: IndexSet, state: inout State) async {
        state.errorMessage = nil

        // Copy filtered boxes to avoid overlapping access
        let filteredBoxes = state.filteredBoxes

        for index in offsets {
            let box = filteredBoxes[index]

            do {
                try await boxRepository.delete(id: box.id)
            } catch {
                state.errorMessage = "Error deleting box: \(error.localizedDescription)"
                print("Error deleting box:", error)
                return
            }
        }

        // Get IDs to delete
        let idsToDelete = Set(offsets.map { filteredBoxes[$0].id })

        // Remove boxes with matching IDs
        state.boxes.removeAll { box in
            idsToDelete.contains(box.id)
        }
    }
}
