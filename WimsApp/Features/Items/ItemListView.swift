//
//  ItemListView.swift
//  Wims
//
//  Created by Camilo Lopez on 1/11/26.
//

import FactoryKit
import PersistencyLayer
import PhotosUI
import SwiftUI

struct ItemListView: View {
    @State private var itemReducer: Reducer<ItemListReducer>

    init() {
        self._itemReducer = State(
            wrappedValue: .init(
                reducer: Container.shared.itemListReducer(),
                initialState: .init()
            )
        )
    }

    var body: some View {
        NavigationStack {
            itemsList
                .navigationTitle("Items")
                .searchable(
                    text: .init(
                        get: { itemReducer.searchText },
                        set: { newValue in
                            Task {
                                await itemReducer.send(action: .setSearchText(newValue))
                            }
                        }
                    ),
                    prompt: "Search items"
                )
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            Task {
                                await itemReducer.send(action: .setShowingAddItemDialog(true))
                            }
                        } label: {
                            Label("Add Item", systemImage: "plus")
                        }
                    }
                }
                .alert("Error", isPresented: .constant(itemReducer.errorMessage != nil)) {
                    Button("OK") {
                        // Error will be cleared by reducer
                    }
                } message: {
                    if let error = itemReducer.errorMessage {
                        Text(error)
                    }
                }
                .task {
                    await itemReducer.send(action: .loadAll)
                }
                .sheet(isPresented: .init(
                    get: { itemReducer.showingAddItemDialog },
                    set: { newValue in
                        Task {
                            await itemReducer.send(action: .setShowingAddItemDialog(newValue))
                        }
                    }
                )) {
                    AddItemFromTabSheet(itemReducer: itemReducer)
                }
        }
    }

    // MARK: - Subviews

    private var itemsList: some View {
        Group {
            if itemReducer.isLoading {
                ProgressView("Loading items...")
            } else if itemReducer.filteredItems.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(itemReducer.filteredItems) { item in
                        NavigationLink {
                            ItemDetailView(item: item, itemReducer: itemReducer)
                        } label: {
                            ItemRowView(item: item)
                        }
                    }
                    .onDelete { offsets in
                        Task {
                            await itemReducer.send(action: .deleteItems(offsets: offsets))
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Items Found", systemImage: "list.bullet.rectangle")
        } description: {
            Text("Items will appear here once you add them to boxes")
        }
    }
}

// MARK: - Supporting Views

struct ItemRowView: View {
    let item: ItemDTO

    var body: some View {
        HStack(spacing: 12) {
            if let imageData = item.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)

                HStack(spacing: 4) {
                    Image(systemName: "shippingbox.fill")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                    Text(item.boxLabel)
                        .font(.caption)
                        .foregroundStyle(.blue)
                }

                Text(item.locationPath)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if let notes = item.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Text(item.createdAt, format: .dateTime)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ItemDetailView: View {
    let item: ItemDTO
    @State var itemReducer: Reducer<ItemListReducer>

    var body: some View {
        List {
            if let imageData = item.imageData, let uiImage = UIImage(data: imageData) {
                Section {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .listRowInsets(EdgeInsets())
                }
            }

            Section("Item Details") {
                LabeledContent("Name", value: item.name)
                if let notes = item.notes, !notes.isEmpty {
                    LabeledContent("Notes") {
                        Text(notes)
                            .multilineTextAlignment(.trailing)
                    }
                }
                LabeledContent("Created") {
                    Text(item.createdAt, format: .dateTime)
                }
            }

            Section("Location") {
                HStack {
                    Image(systemName: "building.2.fill")
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Building")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(item.buildingName)
                            .font(.body)
                    }
                }

                HStack {
                    Image(systemName: "door.left.hand.open")
                        .foregroundStyle(.green)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Room")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(item.roomName)
                            .font(.body)
                    }
                }

                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Spot")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(item.spotName)
                            .font(.body)
                    }
                }

                HStack {
                    Image(systemName: "shippingbox.fill")
                        .foregroundStyle(.purple)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Box")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(item.boxLabel)
                            .font(.body)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    Task {
                        await itemReducer.send(action: .setShowingEditItemSheet(true))
                        await itemReducer.send(action: .setEditItemName(item.name))
                        await itemReducer.send(action: .setEditItemNotes(item.notes ?? ""))
                        await itemReducer.send(action: .setEditItemImageData(item.imageData))
                    }
                }
            }
        }
        .sheet(isPresented: .init(
            get: { itemReducer.showingEditItemSheet },
            set: { newValue in
                Task {
                    await itemReducer.send(action: .setShowingEditItemSheet(newValue))
                }
            }
        )) {
            EditItemFromListSheet(item: item, itemReducer: itemReducer)
        }
    }
}

// MARK: - Preview

#Preview {
    Container.setupForPreviews()
    return ItemListView()
}
