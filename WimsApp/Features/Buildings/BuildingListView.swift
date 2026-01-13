//
//  BuildingListView.swift
//  Wims
//
//  Created by Camilo Lopez on 1/11/26.
//

import PersistencyLayer
import SwiftUI

struct BuildingListView: View {
    @State private var buildingReducer: Reducer<BuildingListViewModel>

    init(buildingRepository: BuildingRepository) {
        self._buildingReducer = State(
            wrappedValue: .init(
                reducer: BuildingListViewModel(buildingRepository: buildingRepository),
                initialState: .init()
            )
        )
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
                .alert("Error", isPresented: .constant(buildingReducer.errorMessage != nil)) {
                    Button("OK") {
                        // Error will be cleared by reducer
                    }
                } message: {
                    if let error = buildingReducer.errorMessage {
                        Text(error)
                    }
                }
                .task {
                    await buildingReducer.send(action: .load)
                }
        } detail: {
            detailPlaceholder
        }
        .sheet(isPresented: .init(
            get: { buildingReducer.showingAddBuildingDialog },
            set: { newValue in
                Task {
                    await buildingReducer.send(action: .setShowingAddBuildingDialog(newValue))
                }
            }
        )) {
            addBuildingSheet
        }
    }

    // MARK: - Subviews

    private var buildingsList: some View {
        Group {
            if buildingReducer.isLoading {
                ProgressView("Loading buildings...")
            } else if buildingReducer.buildings.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(buildingReducer.buildings) { building in
                        NavigationLink {
                            BuildingDetailView(building: building, buildingReducer: buildingReducer)
                        } label: {
                            BuildingRowView(building: building)
                        }
                    }
                    .onDelete { offsets in
                        Task {
                            await buildingReducer.send(action: .deleteBuildings(offsets: offsets))
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
                Task {
                    await buildingReducer.send(action: .setShowingAddBuildingDialog(true))
                }
            }
        }
    }

    private var addButton: some View {
        Button {
            Task {
                await buildingReducer.send(action: .setShowingAddBuildingDialog(true))
            }
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
                    TextField("Building Name", text: .init(
                        get: { buildingReducer.newBuildingName },
                        set: { newValue in
                            Task {
                                await buildingReducer.send(action: .setNewBuildingName(newValue))
                            }
                        }
                    ))
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
                        Task {
                            await buildingReducer.send(action: .setShowingAddBuildingDialog(false))
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            await buildingReducer.send(action: .addBuilding(name: buildingReducer.newBuildingName))
                        }
                    }
                    .disabled(buildingReducer.newBuildingName.isEmpty)
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
    @State var buildingReducer: Reducer<BuildingListViewModel>
    @State private var roomReducer: Reducer<RoomListViewModel>

    init(building: BuildingDTO, buildingReducer: Reducer<BuildingListViewModel>) {
        self.building = building
        self.buildingReducer = buildingReducer
        self._roomReducer = State(
            wrappedValue: .init(
                reducer: RoomListViewModel(
                    roomRepository: RoomRepositoryImpl(container: sharedModelContainer)
                ),
                initialState: .init()
            )
        )
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
                if roomReducer.isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else if roomReducer.rooms.isEmpty {
                    Text("No rooms in this building")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                } else {
                    ForEach(roomReducer.rooms) { room in
                        NavigationLink {
                            RoomDetailView(room: room, roomReducer: roomReducer)
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
                    Task {
                        await buildingReducer.send(action: .setShowingEditBuildingSheet(true))
                        await buildingReducer.send(action: .setEditBuildingName(building.name))
                    }
                }
            }
        }
        .sheet(isPresented: .init(
            get: { buildingReducer.showingEditBuildingSheet },
            set: { newValue in
                Task {
                    await buildingReducer.send(action: .setShowingEditBuildingSheet(newValue))
                }
            }
        )) {
            EditBuildingSheet(building: building, buildingReducer: buildingReducer)
        }
        .task {
            await roomReducer.send(action: .load(building: building))
        }
    }
}

// MARK: - Preview

#Preview {
    BuildingListView(
        buildingRepository: BuildingRepositoryImpl(
            container: sharedModelContainer
        )
    )
}
