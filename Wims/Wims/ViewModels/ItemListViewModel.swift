//
//  ItemListViewModel.swift
//  Wims
//
//  Created by Camilo Lopez on 1/11/26.
//

import Combine
import PersistencyLayer
import SwiftUI

@MainActor
final class ItemListViewModel: ObservableObject {
    private let itemRepository: ItemRepository

    @Published var items: [ItemDTO] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var searchText = ""

    init(itemRepository: ItemRepository) {
        self.itemRepository = itemRepository
    }

    var filteredItems: [ItemDTO] {
        if searchText.isEmpty {
            return items
        }
        return items.filter { item in
            item.name.localizedCaseInsensitiveContains(searchText) ||
            (item.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    func loadAll() async {
        isLoading = true
        errorMessage = nil

        do {
            items = try await itemRepository.fetchAll()
        } catch {
            errorMessage = "Error loading items: \(error.localizedDescription)"
            print("Error loading items:", error)
        }

        isLoading = false
    }

    func load(for box: BoxDTO) async {
        isLoading = true
        errorMessage = nil

        do {
            items = try await itemRepository.fetch(in: box)
        } catch {
            errorMessage = "Error loading items: \(error.localizedDescription)"
            print("Error loading items:", error)
        }

        isLoading = false
    }

    func addItem(name: String, notes: String?, imageData: Data?, in box: BoxDTO) async {
        guard !name.isEmpty else {
            errorMessage = "Item name cannot be empty"
            return
        }

        errorMessage = nil

        do {
            let newItem = try await itemRepository.create(
                name: name,
                notes: notes,
                imageData: imageData,
                in: box
            )
            items.append(newItem)
        } catch {
            errorMessage = "Error creating item: \(error.localizedDescription)"
            print("Error creating item:", error)
        }
    }

    func updateItem(id: UUID, name: String, notes: String?, imageData: Data?) async {
        guard !name.isEmpty else {
            errorMessage = "Item name cannot be empty"
            return
        }

        errorMessage = nil

        do {
            let updatedItem = try await itemRepository.update(
                id: id,
                name: name,
                notes: notes,
                imageData: imageData
            )
            if let index = items.firstIndex(where: { $0.id == id }) {
                items[index] = updatedItem
            }
        } catch {
            errorMessage = "Error updating item: \(error.localizedDescription)"
            print("Error updating item:", error)
        }
    }

    func deleteItems(at offsets: IndexSet) async {
        errorMessage = nil

        for index in offsets {
            let item = filteredItems[index]

            do {
                try await itemRepository.delete(id: item.id)
            } catch {
                errorMessage = "Error deleting item: \(error.localizedDescription)"
                print("Error deleting item:", error)
                return
            }
        }

        items.removeAll { item in
            offsets.contains(where: { filteredItems[$0].id == item.id })
        }
    }
}
