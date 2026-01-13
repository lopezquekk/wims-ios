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

// MARK: - Add Item Sheet

struct AddItemFromTabSheet: View {
    @State var itemReducer: Reducer<ItemListReducer>
    @Environment(\.dismiss) private var dismiss

    @State private var buildings: [BuildingDTO] = []
    @State private var rooms: [RoomDTO] = []
    @State private var spots: [SpotDTO] = []
    @State private var boxes: [BoxDTO] = []

    @State private var selectedBuilding: BuildingDTO?
    @State private var selectedRoom: RoomDTO?
    @State private var selectedSpot: SpotDTO?
    @State private var selectedBox: BoxDTO?

    @State private var itemName = ""
    @State private var itemNotes = ""
    @State private var selectedImage: PhotosPickerItem?
    @State private var imageData: Data?

    @State private var isLoading = false
    @State private var errorMessage: String?

    @Injected(\.buildingRepository) private var buildingRepository
    @Injected(\.roomRepository) private var roomRepository
    @Injected(\.spotRepository) private var spotRepository
    @Injected(\.boxRepository) private var boxRepository

    var body: some View {
        NavigationStack {
            Form {
                Section("Location") {
                    if isLoading {
                        ProgressView("Loading...")
                    } else {
                        Picker("Building", selection: $selectedBuilding) {
                            Text("Select building").tag(nil as BuildingDTO?)
                            ForEach(buildings) { building in
                                Text(building.name).tag(building as BuildingDTO?)
                            }
                        }
                        .onChange(of: selectedBuilding) { _, newValue in
                            selectedRoom = nil
                            selectedSpot = nil
                            selectedBox = nil
                            if let building = newValue {
                                Task { await loadRooms(for: building) }
                            } else {
                                rooms = []
                                spots = []
                                boxes = []
                            }
                        }

                        if !rooms.isEmpty {
                            Picker("Room", selection: $selectedRoom) {
                                Text("Select room").tag(nil as RoomDTO?)
                                ForEach(rooms) { room in
                                    Text(room.name).tag(room as RoomDTO?)
                                }
                            }
                            .onChange(of: selectedRoom) { _, newValue in
                                selectedSpot = nil
                                selectedBox = nil
                                if let room = newValue {
                                    Task { await loadSpots(for: room) }
                                } else {
                                    spots = []
                                    boxes = []
                                }
                            }
                        }

                        if !spots.isEmpty {
                            Picker("Spot", selection: $selectedSpot) {
                                Text("Select spot").tag(nil as SpotDTO?)
                                ForEach(spots) { spot in
                                    Text(spot.name).tag(spot as SpotDTO?)
                                }
                            }
                            .onChange(of: selectedSpot) { _, newValue in
                                selectedBox = nil
                                if let spot = newValue {
                                    Task { await loadBoxes(for: spot) }
                                } else {
                                    boxes = []
                                }
                            }
                        }

                        if !boxes.isEmpty {
                            Picker("Box", selection: $selectedBox) {
                                Text("Select box").tag(nil as BoxDTO?)
                                ForEach(boxes) { box in
                                    Text(box.label).tag(box as BoxDTO?)
                                }
                            }
                        }
                    }
                }

                Section("Item Information") {
                    TextField("Item Name", text: $itemName)
                        .textInputAutocapitalization(.words)
                    TextField("Notes (optional)", text: $itemNotes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Photo") {
                    PhotosPicker(selection: $selectedImage, matching: .images) {
                        HStack {
                            Label("Add Photo", systemImage: "photo")
                            Spacer()
                            if imageData != nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                    .onChange(of: selectedImage) { _, newValue in
                        Task {
                            if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                imageData = data
                            }
                        }
                    }

                    if let data = imageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(8)

                        Button(role: .destructive) {
                            imageData = nil
                            selectedImage = nil
                        } label: {
                            Label("Remove Photo", systemImage: "trash")
                        }
                    }
                }

                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("New Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            await addItem()
                        }
                    }
                    .disabled(itemName.isEmpty || selectedBox == nil)
                }
            }
            .task {
                await loadBuildings()
            }
        }
        .presentationDetents([.large])
    }

    private func loadBuildings() async {
        isLoading = true
        errorMessage = nil
        do {
            buildings = try await buildingRepository.fetchAll()
        } catch {
            errorMessage = "Error loading buildings: \(error.localizedDescription)"
        }
        isLoading = false
    }

    private func loadRooms(for building: BuildingDTO) async {
        errorMessage = nil
        do {
            rooms = try await roomRepository.fetch(in: building)
        } catch {
            errorMessage = "Error loading rooms: \(error.localizedDescription)"
        }
    }

    private func loadSpots(for room: RoomDTO) async {
        errorMessage = nil
        do {
            spots = try await spotRepository.fetch(in: room)
        } catch {
            errorMessage = "Error loading spots: \(error.localizedDescription)"
        }
    }

    private func loadBoxes(for spot: SpotDTO) async {
        errorMessage = nil
        do {
            boxes = try await boxRepository.fetch(in: spot)
        } catch {
            errorMessage = "Error loading boxes: \(error.localizedDescription)"
        }
    }

    private func addItem() async {
        guard let box = selectedBox else {
            errorMessage = "Please select a box"
            return
        }

        await itemReducer.send(action: .addItem(
            name: itemName,
            notes: itemNotes.isEmpty ? nil : itemNotes,
            imageData: imageData,
            box: box
        ))

        if itemReducer.errorMessage == nil {
            dismiss()
        }
    }
}

// MARK: - Edit Item Sheet

struct EditItemFromListSheet: View {
    let item: ItemDTO
    @State var itemReducer: Reducer<ItemListReducer>

    @Environment(\.dismiss) private var dismiss
    @State private var selectedImage: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            Form {
                Section("Item Information") {
                    TextField("Item Name", text: .init(
                        get: { itemReducer.editItemName },
                        set: { newValue in
                            Task {
                                await itemReducer.send(action: .setEditItemName(newValue))
                            }
                        }
                    ))
                        .textInputAutocapitalization(.words)
                    TextField("Notes (optional)", text: .init(
                        get: { itemReducer.editItemNotes },
                        set: { newValue in
                            Task {
                                await itemReducer.send(action: .setEditItemNotes(newValue))
                            }
                        }
                    ), axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Photo") {
                    PhotosPicker(selection: $selectedImage, matching: .images) {
                        Label("Change Photo", systemImage: "photo")
                    }
                    .onChange(of: selectedImage) { _, newValue in
                        Task {
                            if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                await itemReducer.send(action: .setEditItemImageData(data))
                            }
                        }
                    }

                    if let data = itemReducer.editItemImageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(8)

                        Button(role: .destructive) {
                            Task {
                                await itemReducer.send(action: .setEditItemImageData(nil))
                            }
                            selectedImage = nil
                        } label: {
                            Label("Remove Photo", systemImage: "trash")
                        }
                    }
                }

                Section("Location") {
                    LabeledContent("Building", value: item.buildingName)
                    LabeledContent("Room", value: item.roomName)
                    LabeledContent("Spot", value: item.spotName)
                    LabeledContent("Box", value: item.boxLabel)
                }
            }
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await itemReducer.send(action: .updateItem(
                                id: item.id,
                                name: itemReducer.editItemName,
                                notes: itemReducer.editItemNotes.isEmpty ? nil : itemReducer.editItemNotes,
                                imageData: itemReducer.editItemImageData
                            ))
                            dismiss()
                        }
                    }
                    .disabled(itemReducer.editItemName.isEmpty || hasNoChanges)
                }
            }
        }
        .presentationDetents([.large])
    }

    private var hasNoChanges: Bool {
        itemReducer.editItemName == item.name &&
        (itemReducer.editItemNotes.isEmpty ? nil : itemReducer.editItemNotes) == item.notes &&
        itemReducer.editItemImageData == item.imageData
    }
}

// MARK: - Preview

#Preview {
    Container.setupForPreviews()
    return ItemListView()
}
