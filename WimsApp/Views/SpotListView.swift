//
//  SpotListView.swift
//  Wims
//
//  Created by Camilo Lopez on 1/11/26.
//

import PersistencyLayer
import SwiftUI

struct SpotListView: View {
    let room: RoomDTO

    @State private var spotReducer: Reducer<SpotListViewModel>
    @State private var showingAddDialog = false
    @State private var newSpotName = ""

    init(room: RoomDTO) {
        self.room = room
        self._spotReducer = State(
            wrappedValue: .init(
                reducer: SpotListViewModel(
                    spotRepository: SpotRepositoryImpl(
                        container: sharedModelContainer
                    )
                ),
                initialState: .init()
            )
        )
    }

    var body: some View {
        spotsList
            .navigationTitle("Spots")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    addButton
                }
            }
            .alert("Error", isPresented: .constant(spotReducer.errorMessage != nil)) {
                Button("OK") {
                    // spotReducer.errorMessage = nil
                }
            } message: {
                if let error = spotReducer.errorMessage {
                    Text(error)
                }
            }
            .task {
                await spotReducer.send(action: .load(room: room))
            }
            .sheet(isPresented: $showingAddDialog) {
                addSpotSheet
            }
    }

    // MARK: - Subviews

    private var spotsList: some View {
        Group {
            if spotReducer.isLoading {
                ProgressView("Loading spots...")
            } else if spotReducer.spots.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(spotReducer.spots) { spot in
                        NavigationLink {
                            SpotDetailView(spot: spot, spotReducer: spotReducer)
                        } label: {
                            SpotRowView(spot: spot)
                        }
                    }
                    .onDelete { offsets in
                        Task {
                            await spotReducer.send(action: .deleteSpots(offsets: offsets))
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Spots", systemImage: "mappin.and.ellipse")
        } description: {
            Text("Add your first spot to get started")
        } actions: {
            Button("Add Spot") {
                showingAddDialog = true
            }
        }
    }

    private var addButton: some View {
        Button {
            showingAddDialog = true
        } label: {
            Label("Add Spot", systemImage: "plus")
        }
    }

    private var addSpotSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Spot Name", text: $newSpotName)
                        .textInputAutocapitalization(.words)
                } header: {
                    Text("Spot Information")
                }
            }
            .navigationTitle("New Spot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingAddDialog = false
                        newSpotName = ""
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            await spotReducer.send(action: .addSpot(name: newSpotName, room: room))
                            showingAddDialog = false
                            newSpotName = ""
                        }
                    }
                    .disabled(newSpotName.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Supporting Views

struct SpotRowView: View {
    let spot: SpotDTO

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(spot.name)
                .font(.headline)
            Text(spot.createdAt, format: .dateTime)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct SpotDetailView: View {
    let spot: SpotDTO
    @State private var spotReducer: Reducer<SpotListViewModel>
    @State private var showingEditSheet = false
    @State private var boxViewModel: BoxListViewModel

    init(spot: SpotDTO, spotReducer: Reducer<SpotListViewModel>) {
        self.spot = spot
        self.spotReducer = spotReducer
        self._boxViewModel = State(wrappedValue: BoxListViewModel(
            boxRepository: BoxRepositoryImpl(container: sharedModelContainer)
        ))
    }

    var body: some View {
        List {
            Section("Details") {
                LabeledContent("Name", value: spot.name)
                LabeledContent("Created") {
                    Text(spot.createdAt, format: .dateTime)
                }
            }

            Section {
                if boxViewModel.isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else if boxViewModel.boxes.isEmpty {
                    Text("No boxes in this spot")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                } else {
                    ForEach(boxViewModel.boxes) { box in
                        NavigationLink {
                            BoxDetailView(box: box)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(box.label)
                                    .font(.body)
                                    .fontWeight(.medium)
                                HStack(spacing: 4) {
                                    Image(systemName: "qrcode")
                                        .font(.caption2)
                                    Text(box.qrCode)
                                        .font(.caption)
                                }
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            } header: {
                Text("Boxes")
            }
        }
        .navigationTitle(spot.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    showingEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditSpotSheet(spot: spot, spotReducer: spotReducer)
        }
        .task {
            await boxViewModel.load(for: spot)
        }
    }
}

struct EditSpotSheet: View {
    let spot: SpotDTO
    @State var spotReducer: Reducer<SpotListViewModel>

    @Environment(\.dismiss) private var dismiss
    @State private var spotName: String

    init(spot: SpotDTO, spotReducer: Reducer<SpotListViewModel>) {
        self.spot = spot
        self.spotReducer = spotReducer
        self._spotName = State(initialValue: spot.name)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Spot Name", text: $spotName)
                        .textInputAutocapitalization(.words)
                } header: {
                    Text("Spot Information")
                } footer: {
                    Text("Enter a new name for this spot")
                }
            }
            .navigationTitle("Edit Spot")
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
                            await spotReducer.send(action: .updateSpot(id: spot.id, name: spotName))
                            dismiss()
                        }
                    }
                    .disabled(spotName.isEmpty || spotName == spot.name)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SpotListView(
            room: RoomDTO(
                id: UUID(),
                name: "Sample Room",
                buildingID: UUID(),
                createdAt: Date()
            )
        )
    }
}
