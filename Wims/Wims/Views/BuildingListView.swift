//
//  BuildingListView.swift
//  Wims
//
//  Created by Camilo Lopez on 1/11/26.
//

import SwiftUI
import PersistencyLayer

struct BuildingListView: View {

    @State private var viewModel: BuildingListViewModel
    @State private var showingAddDialog = false
    @State private var newBuildingName = ""

    init(viewModel: BuildingListViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationSplitView {
            buildingsList
                .navigationTitle("Buildings")
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
                    await viewModel.load()
                }
        } detail: {
            detailPlaceholder
        }
        .sheet(isPresented: $showingAddDialog) {
            addBuildingSheet
        }
    }

    // MARK: - Subviews

    private var buildingsList: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading buildings...")
            } else if viewModel.buildings.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(viewModel.buildings) { building in
                        NavigationLink {
                            BuildingDetailView(building: building)
                        } label: {
                            BuildingRowView(building: building)
                        }
                    }
                    .onDelete { offsets in
                        Task {
                            await viewModel.deleteBuildings(at: offsets)
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Buildings", systemImage: "building.2")
        } description: {
            Text("Add your first building to get started")
        } actions: {
            Button("Add Building") {
                showingAddDialog = true
            }
        }
    }

    private var addButton: some View {
        Button {
            showingAddDialog = true
        } label: {
            Label("Add Building", systemImage: "plus")
        }
    }

    private var detailPlaceholder: some View {
        ContentUnavailableView {
            Label("Select a Building", systemImage: "building.2")
        } description: {
            Text("Choose a building from the list to view its details")
        }
    }

    private var addBuildingSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Building Name", text: $newBuildingName)
                        .textInputAutocapitalization(.words)
                } header: {
                    Text("Building Information")
                }
            }
            .navigationTitle("New Building")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingAddDialog = false
                        newBuildingName = ""
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            await viewModel.addBuilding(name: newBuildingName)
                            showingAddDialog = false
                            newBuildingName = ""
                        }
                    }
                    .disabled(newBuildingName.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Supporting Views

struct BuildingRowView: View {
    let building: BuildingDTO

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(building.name)
                .font(.headline)
            Text(building.createdAt, format: .dateTime)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct BuildingDetailView: View {
    let building: BuildingDTO
    @State private var showingEditSheet = false
    @StateObject private var roomViewModel: RoomListViewModel

    init(building: BuildingDTO) {
        self.building = building
        self._roomViewModel = StateObject(wrappedValue: RoomListViewModel(
            roomRepository: RoomRepositoryImpl(container: sharedModelContainer)
        ))
    }

    var body: some View {
        List {
            Section("Details") {
                LabeledContent("Name", value: building.name)
                LabeledContent("Created") {
                    Text(building.createdAt, format: .dateTime)
                }
            }

            Section {
                if roomViewModel.isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else if roomViewModel.rooms.isEmpty {
                    Text("No rooms in this building")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                } else {
                    ForEach(roomViewModel.rooms) { room in
                        NavigationLink {
                            RoomDetailView(room: room, viewModel: roomViewModel)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(room.name)
                                    .font(.body)
                                    .fontWeight(.medium)
                                Text(room.createdAt, format: .dateTime)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            } header: {
                Text("Rooms")
            }
        }
        .navigationTitle(building.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    showingEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditBuildingSheet(building: building)
        }
        .task {
            await roomViewModel.load(for: building)
        }
    }
}

// MARK: - Preview

#Preview {
    BuildingListView(
        viewModel: BuildingListViewModel(
            buildingRepository: BuildingRepositoryImpl(
                container: sharedModelContainer
            )
        )
    )
}
