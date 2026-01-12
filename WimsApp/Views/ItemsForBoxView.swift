//
//  ItemsForBoxView.swift
//  Wims
//
//  Created by Camilo Lopez on 1/11/26.
//

import PersistencyLayer
import PhotosUI
import SwiftUI

struct ItemsForBoxView: View {
    let box: BoxDTO

    @StateObject private var viewModel: ItemListViewModel
    @State private var showingAddDialog = false
    @State private var newItemName = ""
    @State private var newItemNotes = ""
    @State private var newItemImage: PhotosPickerItem?
    @State private var newItemImageData: Data?

    init(box: BoxDTO) {
        self.box = box
        self._viewModel = StateObject(wrappedValue: ItemListViewModel(
            itemRepository: ItemRepositoryImpl(container: sharedModelContainer)
        ))
    }

    var body: some View {
        itemsList
            .navigationTitle("Items")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    addButton
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
            .task {
                await viewModel.load(for: box)
            }
            .sheet(isPresented: $showingAddDialog) {
                addItemSheet
            }
    }

    // MARK: - Subviews

    private var itemsList: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading items...")
            } else if viewModel.items.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(viewModel.items) { item in
                        NavigationLink {
                            ItemForBoxDetailView(item: item, viewModel: viewModel)
                        } label: {
                            ItemForBoxRowView(item: item)
                        }
                    }
                    .onDelete { offsets in
                        Task {
                            await viewModel.deleteItems(at: offsets)
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Items", systemImage: "tray")
        } description: {
            Text("Add your first item to get started")
        } actions: {
            Button("Add Item") {
                showingAddDialog = true
            }
        }
    }

    private var addButton: some View {
        Button {
            showingAddDialog = true
        } label: {
            Label("Add Item", systemImage: "plus")
        }
    }

    private var addItemSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Item Name", text: $newItemName)
                        .textInputAutocapitalization(.words)
                    TextField("Notes (optional)", text: $newItemNotes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Item Information")
                }

                Section {
                    PhotosPicker(selection: $newItemImage, matching: .images) {
                        HStack {
                            Label("Add Photo", systemImage: "photo")
                            Spacer()
                            if newItemImageData != nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            }
                        }
                    }
                    .onChange(of: newItemImage) { _, newValue in
                        Task {
                            if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                newItemImageData = data
                            }
                        }
                    }

                    if let imageData = newItemImageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(8)
                    }
                } header: {
                    Text("Photo")
                }
            }
            .navigationTitle("New Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingAddDialog = false
                        resetAddForm()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            await viewModel.addItem(
                                name: newItemName,
                                notes: newItemNotes.isEmpty ? nil : newItemNotes,
                                imageData: newItemImageData,
                                in: box
                            )
                            showingAddDialog = false
                            resetAddForm()
                        }
                    }
                    .disabled(newItemName.isEmpty)
                }
            }
        }
        .presentationDetents([.large])
    }

    private func resetAddForm() {
        newItemName = ""
        newItemNotes = ""
        newItemImage = nil
        newItemImageData = nil
    }
}

// MARK: - Supporting Views

struct ItemForBoxRowView: View {
    let item: ItemDTO

    var body: some View {
        HStack(spacing: 12) {
            if let imageData = item.imageData,
               let uiImage = UIImage(data: imageData) {
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

                Text("📍 \(item.locationPath)")
                    .font(.caption2)
                    .foregroundStyle(.blue)
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

struct ItemForBoxDetailView: View {
    let item: ItemDTO
    @ObservedObject var viewModel: ItemListViewModel
    @State private var showingEditSheet = false

    var body: some View {
        List {
            if let imageData = item.imageData,
               let uiImage = UIImage(data: imageData) {
                Section {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .listRowInsets(EdgeInsets())
                }
            }

            Section("Details") {
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
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    showingEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditItemSheet(item: item, viewModel: viewModel)
        }
    }
}

struct EditItemSheet: View {
    let item: ItemDTO
    @ObservedObject var viewModel: ItemListViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var itemName: String
    @State private var itemNotes: String
    @State private var selectedImage: PhotosPickerItem?
    @State private var imageData: Data?

    init(item: ItemDTO, viewModel: ItemListViewModel) {
        self.item = item
        self.viewModel = viewModel
        self._itemName = State(initialValue: item.name)
        self._itemNotes = State(initialValue: item.notes ?? "")
        self._imageData = State(initialValue: item.imageData)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Item Name", text: $itemName)
                        .textInputAutocapitalization(.words)
                    TextField("Notes (optional)", text: $itemNotes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Item Information")
                }

                Section {
                    PhotosPicker(selection: $selectedImage, matching: .images) {
                        Label("Change Photo", systemImage: "photo")
                    }
                    .onChange(of: selectedImage) { _, newValue in
                        Task {
                            if let data = try? await newValue?.loadTransferable(type: Data.self) {
                                imageData = data
                            }
                        }
                    }

                    if let data = imageData,
                       let uiImage = UIImage(data: data) {
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
                } header: {
                    Text("Photo")
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
                            await viewModel.updateItem(
                                id: item.id,
                                name: itemName,
                                notes: itemNotes.isEmpty ? nil : itemNotes,
                                imageData: imageData
                            )
                            dismiss()
                        }
                    }
                    .disabled(itemName.isEmpty || hasNoChanges)
                }
            }
        }
        .presentationDetents([.large])
    }

    private var hasNoChanges: Bool {
        itemName == item.name &&
        (itemNotes.isEmpty ? nil : itemNotes) == item.notes &&
        imageData == item.imageData
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ItemsForBoxView(
            box: BoxDTO(
                id: UUID(),
                label: "Sample Box",
                qrCode: "QR123",
                spotID: UUID(),
                createdAt: Date(),
                spotName: "Sample Spot",
                roomName: "Sample Room",
                buildingName: "Sample Building"
            )
        )
    }
}
