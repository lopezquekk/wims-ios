//
//  RoomListView.swift
//  Wims
//
//  Created by Camilo Lopez on 1/11/26.
//

import PersistencyLayer
import SwiftUI

struct RoomListView: View {
    let building: BuildingDTO

    @State private var roomReducer: Reducer<RoomListViewModel>

    init(building: BuildingDTO) {
        self.building = building
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
        roomsList
            .navigationTitle("Rooms")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    addButton
                }
            }
            .alert("Error", isPresented: .constant(roomReducer.errorMessage != nil)) {
                Button("OK") {
                    // Error will be cleared by reducer
                }
            } message: {
                if let error = roomReducer.errorMessage {
                    Text(error)
                }
            }
            .task {
                await roomReducer.send(action: .load(building: building))
            }
            .sheet(isPresented: .init(
                get: { roomReducer.showingAddRoomDialog },
                set: { newValue in
                    Task {
                        await roomReducer.send(action: .setShowingAddRoomDialog(newValue))
                    }
                }
            )) {
                addRoomSheet
            }
    }

    // MARK: - Subviews

    private var roomsList: some View {
        Group {
            if roomReducer.isLoading {
                ProgressView("Loading rooms...")
            } else if roomReducer.rooms.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(roomReducer.rooms) { room in
                        NavigationLink {
                            RoomDetailView(room: room, roomReducer: roomReducer)
                        } label: {
                            RoomRowView(room: room)
                        }
                    }
                    .onDelete { offsets in
                        Task {
                            await roomReducer.send(action: .deleteRooms(offsets: offsets))
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Rooms", systemImage: "door.left.hand.open")
        } description: {
            Text("Add your first room to get started")
        } actions: {
            Button("Add Room") {
                Task {
                    await roomReducer.send(action: .setShowingAddRoomDialog(true))
                }
            }
        }
    }

    private var addButton: some View {
        Button {
            Task {
                await roomReducer.send(action: .setShowingAddRoomDialog(true))
            }
        } label: {
            Label("Add Room", systemImage: "plus")
        }
    }

    private var addRoomSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Room Name", text: .init(
                        get: { roomReducer.newRoomName },
                        set: { newValue in
                            Task {
                                await roomReducer.send(action: .setNewRoomName(newValue))
                            }
                        }
                    ))
                        .textInputAutocapitalization(.words)
                } header: {
                    Text("Room Information")
                }
            }
            .navigationTitle("New Room")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        Task {
                            await roomReducer.send(action: .setShowingAddRoomDialog(false))
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            await roomReducer.send(action: .addRoom(name: roomReducer.newRoomName, building: building))
                        }
                    }
                    .disabled(roomReducer.newRoomName.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Supporting Views

struct RoomRowView: View {
    let room: RoomDTO

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(room.name)
                .font(.headline)
            Text(room.createdAt, format: .dateTime)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct RoomDetailView: View {
    let room: RoomDTO
    @State var roomReducer: Reducer<RoomListViewModel>
    @State private var spotReducer: Reducer<SpotListViewModel>

    init(room: RoomDTO, roomReducer: Reducer<RoomListViewModel>) {
        self.room = room
        self.roomReducer = roomReducer
        self._spotReducer = State(
            wrappedValue: .init(
                reducer: SpotListViewModel(
                    spotRepository: SpotRepositoryImpl(
                        container: sharedModelContainer
                    ),
                    boxRepository: BoxRepositoryImpl(
                        container: sharedModelContainer
                    )
                ),
                initialState: .init()
            )
        )
    }

    var body: some View {
        List {
            Section("Details") {
                LabeledContent("Name", value: room.name)
                LabeledContent("Created") {
                    Text(room.createdAt, format: .dateTime)
                }
            }

            Section {
                if spotReducer.isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else if spotReducer.spots.isEmpty {
                    Text("No spots in this room")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                } else {
                    ForEach(spotReducer.spots) { spot in
                        NavigationLink {
                            SpotDetailView(spot: spot, spotReducer: spotReducer, room: room)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(spot.name)
                                    .font(.body)
                                    .fontWeight(.medium)
                                Text(spot.createdAt, format: .dateTime)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete { offsets in
                        Task {
                            await spotReducer.send(action: .deleteSpots(offsets: offsets))
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Spots")
                    Spacer()
                    Button {
                        Task {
                            await spotReducer.send(action: .setShowingAddSpotDialog(true))
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle(room.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    Task {
                        await roomReducer.send(action: .setShowingEditRoomSheet(true))
                        await roomReducer.send(action: .setEditRoomName(room.name))
                    }
                }
            }
        }
        .sheet(isPresented: .init(
            get: { roomReducer.showingEditRoomSheet },
            set: { newValue in
                Task {
                    await roomReducer.send(action: .setShowingEditRoomSheet(newValue))
                }
            }
        )) {
            EditRoomSheet(room: room, roomReducer: roomReducer)
        }
        .sheet(isPresented: .init(
            get: { spotReducer.showingAddSpotDialog },
            set: { newValue in
                Task {
                    await spotReducer.send(action: .setShowingAddSpotDialog(newValue))
                }
            }
        )) {
            addSpotSheet
        }
        .task {
            await spotReducer.send(action: .load(room: room))
        }
    }

    private var addSpotSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Spot Name", text: .init(
                        get: { spotReducer.newSpotName },
                        set: { newValue in
                            Task {
                                await spotReducer.send(action: .setNewSpotName(newValue))
                            }
                        }
                    ))
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
                        Task {
                            await spotReducer.send(action: .setShowingAddSpotDialog(false))
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            await spotReducer.send(action: .addSpot(name: spotReducer.newSpotName, room: room))
                        }
                    }
                    .disabled(spotReducer.newSpotName.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct EditRoomSheet: View {
    let room: RoomDTO
    @State var roomReducer: Reducer<RoomListViewModel>

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Room Name", text: .init(
                        get: { roomReducer.editRoomName },
                        set: { newValue in
                            Task {
                                await roomReducer.send(action: .setEditRoomName(newValue))
                            }
                        }
                    ))
                        .textInputAutocapitalization(.words)
                } header: {
                    Text("Room Information")
                } footer: {
                    Text("Enter a new name for this room")
                }
            }
            .navigationTitle("Edit Room")
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
                            await roomReducer.send(action: .updateRoom(id: room.id, name: roomReducer.editRoomName))
                            dismiss()
                        }
                    }
                    .disabled(roomReducer.editRoomName.isEmpty || roomReducer.editRoomName == room.name)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RoomListView(
            building: BuildingDTO(
                id: UUID(),
                name: "Sample Building",
                createdAt: Date()
            )
        )
    }
}
