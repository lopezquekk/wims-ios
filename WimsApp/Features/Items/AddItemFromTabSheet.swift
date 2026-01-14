//
//  AddItemFromTabSheet.swift
//  Wims
//
//  Created by Camilo Lopez on 1/14/26.
//

import FactoryKit
import PersistencyLayer
import PhotosUI
import SwiftUI

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
