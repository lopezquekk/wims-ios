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

    @StateObject private var viewModel: SpotListViewModel
    @State private var showingAddDialog = false
    @State private var newSpotName = ""

    init(room: RoomDTO) {
        self.room = room
        self._viewModel = StateObject(wrappedValue: SpotListViewModel(
            spotRepository: SpotRepositoryImpl(container: sharedModelContainer)
        ))
    }

    var body: some View {
        spotsList
            .navigationTitle("Spots")
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
                await viewModel.load(for: room)
            }
            .sheet(isPresented: $showingAddDialog) {
                addSpotSheet
            }
    }

    // MARK: - Subviews

    private var spotsList: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading spots...")
            } else if viewModel.spots.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(viewModel.spots) { spot in
                        NavigationLink {
                            SpotDetailView(spot: spot, viewModel: viewModel)
                        } label: {
                            SpotRowView(spot: spot)
                        }
                    }
                    .onDelete { offsets in
                        Task {
                            await viewModel.deleteSpots(at: offsets)
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
                            await viewModel.addSpot(name: newSpotName, in: room)
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
    @ObservedObject var viewModel: SpotListViewModel
    @State private var showingEditSheet = false
    @StateObject private var boxViewModel: BoxListViewModel

    init(spot: SpotDTO, viewModel: SpotListViewModel) {
        self.spot = spot
        self.viewModel = viewModel
        self._boxViewModel = StateObject(wrappedValue: BoxListViewModel(
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
            EditSpotSheet(spot: spot, viewModel: viewModel)
        }
        .task {
            await boxViewModel.load(for: spot)
        }
    }
}

struct EditSpotSheet: View {
    let spot: SpotDTO
    @ObservedObject var viewModel: SpotListViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var spotName: String

    init(spot: SpotDTO, viewModel: SpotListViewModel) {
        self.spot = spot
        self.viewModel = viewModel
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
                            await viewModel.updateSpot(id: spot.id, name: spotName)
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
