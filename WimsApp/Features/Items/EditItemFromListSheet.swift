//
//  EditItemFromListSheet.swift
//  Wims
//
//  Created by Camilo Lopez on 1/14/26.
//

import PersistencyLayer
import PhotosUI
import SwiftUI

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
