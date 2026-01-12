//
//  BoxListViewModel.swift
//  Wims
//
//  Created by Camilo Lopez on 1/11/26.
//

import Combine
import PersistencyLayer
import SwiftUI

@MainActor
final class BoxListViewModel: ObservableObject {
    private let boxRepository: BoxRepository

    @Published var boxes: [BoxDTO] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""

    init(boxRepository: BoxRepository) {
        self.boxRepository = boxRepository
    }

    var filteredBoxes: [BoxDTO] {
        if searchText.isEmpty {
            return boxes
        }
        return boxes.filter { box in
            box.label.localizedCaseInsensitiveContains(searchText) ||
            box.qrCode.localizedCaseInsensitiveContains(searchText)
        }
    }

    func loadAll() async {
        isLoading = true
        errorMessage = nil

        do {
            boxes = try await boxRepository.fetchAll()
        } catch {
            errorMessage = "Error loading boxes: \(error.localizedDescription)"
            print("Error loading boxes:", error)
        }

        isLoading = false
    }

    func load(for spot: SpotDTO) async {
        isLoading = true
        errorMessage = nil

        do {
            boxes = try await boxRepository.fetch(in: spot)
        } catch {
            errorMessage = "Error loading boxes: \(error.localizedDescription)"
            print("Error loading boxes:", error)
        }

        isLoading = false
    }

    func searchBox(byQRCode qrCode: String) async {
        guard !qrCode.isEmpty else {
            errorMessage = "QR Code cannot be empty"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            if let box = try await boxRepository.fetch(byQRCode: qrCode) {
                // Clear and show only the found box
                boxes = [box]
            } else {
                errorMessage = "No box found with QR code: \(qrCode)"
                boxes = []
            }
        } catch {
            errorMessage = "Error searching box: \(error.localizedDescription)"
            print("Error searching box:", error)
        }

        isLoading = false
    }

    func addBox(label: String, qrCode: String, in spot: SpotDTO) async {
        guard !label.isEmpty else {
            errorMessage = "Box label cannot be empty"
            return
        }

        guard !qrCode.isEmpty else {
            errorMessage = "QR code cannot be empty"
            return
        }

        errorMessage = nil

        do {
            let newBox = try await boxRepository.create(label: label, qrCode: qrCode, in: spot)
            boxes.append(newBox)
        } catch {
            errorMessage = "Error creating box: \(error.localizedDescription)"
            print("Error creating box:", error)
        }
    }

    func updateBox(id: UUID, label: String, qrCode: String) async {
        guard !label.isEmpty else {
            errorMessage = "Box label cannot be empty"
            return
        }

        guard !qrCode.isEmpty else {
            errorMessage = "QR code cannot be empty"
            return
        }

        errorMessage = nil

        do {
            let updatedBox = try await boxRepository.update(id: id, label: label, qrCode: qrCode)
            if let index = boxes.firstIndex(where: { $0.id == id }) {
                boxes[index] = updatedBox
            }
        } catch {
            errorMessage = "Error updating box: \(error.localizedDescription)"
            print("Error updating box:", error)
        }
    }

    func deleteBoxes(at offsets: IndexSet) async {
        errorMessage = nil

        for index in offsets {
            let box = filteredBoxes[index]

            do {
                try await boxRepository.delete(id: box.id)
            } catch {
                errorMessage = "Error deleting box: \(error.localizedDescription)"
                print("Error deleting box:", error)
                return
            }
        }

        boxes.removeAll { box in
            offsets.contains(where: { filteredBoxes[$0].id == box.id })
        }
    }
}
