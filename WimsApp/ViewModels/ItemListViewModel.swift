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
struct ItemListViewModel: ReducerProtocol {
    struct State: Sendable {
        // Item list state
        var items: [ItemDTO] = []
        var isLoading = false
        var errorMessage: String?
        var searchText = ""

        // Item form state
        var showingAddItemDialog = false
        var newItemName = ""
        var newItemNotes = ""
        var newItemImageData: Data?

        // Item edit state
        var showingEditItemSheet = false
        var editItemName = ""
        var editItemNotes = ""
        var editItemImageData: Data?

        // Computed property for filtered items
        var filteredItems: [ItemDTO] {
            if searchText.isEmpty {
                return items
            }
            return items.filter { item in
                item.name.localizedCaseInsensitiveContains(searchText) ||
                (item.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }

    enum Action: Equatable, Sendable {
        // Item actions
        case loadAll
        case load(box: BoxDTO)
        case addItem(name: String, notes: String?, imageData: Data?, box: BoxDTO)
        case updateItem(id: UUID, name: String, notes: String?, imageData: Data?)
        case deleteItems(offsets: IndexSet)

        // UI actions
        case setSearchText(String)
        case setShowingAddItemDialog(Bool)
        case setNewItemName(String)
        case setNewItemNotes(String)
        case setNewItemImageData(Data?)
        case setShowingEditItemSheet(Bool)
        case setEditItemName(String)
        case setEditItemNotes(String)
        case setEditItemImageData(Data?)
        case clearItemForm
    }

    private let itemRepository: ItemRepository

    init(itemRepository: ItemRepository) {
        self.itemRepository = itemRepository
    }

    func reduce(state: inout State, action: Action) async {
        switch action {
        // Item actions
        case .loadAll:
            await loadAll(state: &state)
        case let .load(box):
            await load(for: box, state: &state)
        case let .addItem(name, notes, imageData, box):
            await addItem(name: name, notes: notes, imageData: imageData, in: box, state: &state)
        case let .updateItem(id, name, notes, imageData):
            await updateItem(id: id, name: name, notes: notes, imageData: imageData, state: &state)
        case let .deleteItems(offsets):
            await deleteItems(at: offsets, state: &state)

        // UI actions
        case let .setSearchText(text):
            state.searchText = text
        case let .setShowingAddItemDialog(showing):
            state.showingAddItemDialog = showing
            if !showing {
                state.newItemName = ""
                state.newItemNotes = ""
                state.newItemImageData = nil
            }
        case let .setNewItemName(name):
            state.newItemName = name
        case let .setNewItemNotes(notes):
            state.newItemNotes = notes
        case let .setNewItemImageData(data):
            state.newItemImageData = data
        case let .setShowingEditItemSheet(showing):
            state.showingEditItemSheet = showing
        case let .setEditItemName(name):
            state.editItemName = name
        case let .setEditItemNotes(notes):
            state.editItemNotes = notes
        case let .setEditItemImageData(data):
            state.editItemImageData = data
        case .clearItemForm:
            state.newItemName = ""
            state.newItemNotes = ""
            state.newItemImageData = nil
        }
    }

    // MARK: - Item Methods

    private func loadAll(state: inout State) async {
        state.isLoading = true
        state.errorMessage = nil

        do {
            state.items = try await itemRepository.fetchAll()
        } catch {
            state.errorMessage = "Error loading items: \(error.localizedDescription)"
            print("Error loading items:", error)
        }

        state.isLoading = false
    }

    private func load(for box: BoxDTO, state: inout State) async {
        state.isLoading = true
        state.errorMessage = nil

        do {
            state.items = try await itemRepository.fetch(in: box)
        } catch {
            state.errorMessage = "Error loading items: \(error.localizedDescription)"
            print("Error loading items:", error)
        }

        state.isLoading = false
    }

    private func addItem(name: String, notes: String?, imageData: Data?, in box: BoxDTO, state: inout State) async {
        guard !name.isEmpty else {
            state.errorMessage = "Item name cannot be empty"
            return
        }

        state.errorMessage = nil

        do {
            let newItem = try await itemRepository.create(
                name: name,
                notes: notes,
                imageData: imageData,
                in: box
            )
            state.items.append(newItem)
            state.showingAddItemDialog = false
            state.newItemName = ""
            state.newItemNotes = ""
            state.newItemImageData = nil
        } catch {
            state.errorMessage = "Error creating item: \(error.localizedDescription)"
            print("Error creating item:", error)
        }
    }

    private func updateItem(id: UUID, name: String, notes: String?, imageData: Data?, state: inout State) async {
        guard !name.isEmpty else {
            state.errorMessage = "Item name cannot be empty"
            return
        }

        state.errorMessage = nil

        do {
            let updatedItem = try await itemRepository.update(
                id: id,
                name: name,
                notes: notes,
                imageData: imageData
            )
            if let index = state.items.firstIndex(where: { $0.id == id }) {
                state.items[index] = updatedItem
            }
            state.showingEditItemSheet = false
        } catch {
            state.errorMessage = "Error updating item: \(error.localizedDescription)"
            print("Error updating item:", error)
        }
    }

    private func deleteItems(at offsets: IndexSet, state: inout State) async {
        state.errorMessage = nil

        // Copy filtered items to avoid overlapping access
        let filteredItems = state.filteredItems

        for index in offsets {
            let item = filteredItems[index]

            do {
                try await itemRepository.delete(id: item.id)
            } catch {
                state.errorMessage = "Error deleting item: \(error.localizedDescription)"
                print("Error deleting item:", error)
                return
            }
        }

        // Get IDs to delete
        let idsToDelete = Set(offsets.map { filteredItems[$0].id })

        // Remove items with matching IDs
        state.items.removeAll { item in
            idsToDelete.contains(item.id)
        }
    }
}
