//
//  RoomListView.swift
//  Wims
//
//  Created by Camilo Lopez on 1/11/26.
//

import SwiftUI
import PersistencyLayer

struct RoomListView: View {
    let building: BuildingDTO

    @StateObject private var viewModel: RoomListViewModel
    @State private var showingAddDialog = false
    @State private var newRoomName = ""

    init(building: BuildingDTO) {
        self.building = building
        self._viewModel = StateObject(wrappedValue: RoomListViewModel(
            roomRepository: RoomRepositoryImpl(container: sharedModelContainer)
        ))
    }

    var body: some View {
        roomsList
            .navigationTitle("Rooms")
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
                await viewModel.load(for: building)
            }
            .sheet(isPresented: $showingAddDialog) {
                addRoomSheet
            }
    }

    // MARK: - Subviews

    private var roomsList: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading rooms...")
            } else if viewModel.rooms.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(viewModel.rooms) { room in
                        NavigationLink {
                            RoomDetailView(room: room, viewModel: viewModel)
                        } label: {
                            RoomRowView(room: room)
                        }
                    }
                    .onDelete { offsets in
                        Task {
                            await viewModel.deleteRooms(at: offsets)
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
                showingAddDialog = true
            }
        }
    }

    private var addButton: some View {
        Button {
            showingAddDialog = true
        } label: {
            Label("Add Room", systemImage: "plus")
        }
    }

    private var addRoomSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Room Name", text: $newRoomName)
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
                        showingAddDialog = false
                        newRoomName = ""
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            await viewModel.addRoom(name: newRoomName, in: building)
                            showingAddDialog = false
                            newRoomName = ""
                        }
                    }
                    .disabled(newRoomName.isEmpty)
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
    @ObservedObject var viewModel: RoomListViewModel
    @State private var showingEditSheet = false
    @StateObject private var spotViewModel: SpotListViewModel

    init(room: RoomDTO, viewModel: RoomListViewModel) {
        self.room = room
        self.viewModel = viewModel
        self._spotViewModel = StateObject(wrappedValue: SpotListViewModel(
            spotRepository: SpotRepositoryImpl(container: sharedModelContainer)
        ))
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
                if spotViewModel.isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else if spotViewModel.spots.isEmpty {
                    Text("No spots in this room")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                } else {
                    ForEach(spotViewModel.spots) { spot in
                        NavigationLink {
                            SpotDetailView(spot: spot, viewModel: spotViewModel)
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
                }
            } header: {
                Text("Spots")
            }
        }
        .navigationTitle(room.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    showingEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditRoomSheet(room: room, viewModel: viewModel)
        }
        .task {
            await spotViewModel.load(for: room)
        }
    }
}

struct EditRoomSheet: View {
    let room: RoomDTO
    @ObservedObject var viewModel: RoomListViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var roomName: String

    init(room: RoomDTO, viewModel: RoomListViewModel) {
        self.room = room
        self.viewModel = viewModel
        self._roomName = State(initialValue: room.name)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Room Name", text: $roomName)
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
                            await viewModel.updateRoom(id: room.id, name: roomName)
                            dismiss()
                        }
                    }
                    .disabled(roomName.isEmpty || roomName == room.name)
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
