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

    @State private var spotReducer: Reducer<SpotListReducer>

    init(room: RoomDTO) {
        self.room = room
        self._spotReducer = State(
            wrappedValue: .init(
                reducer: SpotListReducer(
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
        spotsList
            .navigationTitle("Spots")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    addButton
                }
            }
            .alert("Error", isPresented: .constant(spotReducer.errorMessage != nil)) {
                Button("OK") {
                    // Error will be cleared by reducer
                }
            } message: {
                if let error = spotReducer.errorMessage {
                    Text(error)
                }
            }
            .task {
                await spotReducer.send(action: .load(room: room))
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
                            SpotDetailView(spot: spot, spotReducer: spotReducer, room: room)
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
                Task {
                    await spotReducer.send(action: .setShowingAddSpotDialog(true))
                }
            }
        }
    }

    private var addButton: some View {
        Button {
            Task {
                await spotReducer.send(action: .setShowingAddSpotDialog(true))
            }
        } label: {
            Label("Add Spot", systemImage: "plus")
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
    let room: RoomDTO
    @State var spotReducer: Reducer<SpotListReducer>

    init(spot: SpotDTO, spotReducer: Reducer<SpotListReducer>, room: RoomDTO) {
        self.spot = spot
        self.spotReducer = spotReducer
        self.room = room
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
                if spotReducer.boxesLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else if spotReducer.boxes.isEmpty {
                    Text("No boxes in this spot")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                } else {
                    ForEach(spotReducer.boxes) { box in
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
                    .onDelete { offsets in
                        Task {
                            await spotReducer.send(action: .deleteBoxes(offsets: offsets))
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Boxes")
                    Spacer()
                    Button {
                        Task {
                            await spotReducer.send(action: .setShowingAddBoxDialog(true))
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle(spot.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    Task {
                        await spotReducer.send(action: .setShowingEditSpotSheet(true))
                        await spotReducer.send(action: .setEditSpotName(spot.name))
                    }
                }
            }
        }
        .sheet(isPresented: .init(
            get: { spotReducer.showingEditSpotSheet },
            set: { newValue in
                Task {
                    await spotReducer.send(action: .setShowingEditSpotSheet(newValue))
                }
            }
        )) {
            EditSpotSheet(spot: spot, spotReducer: spotReducer)
        }
        .sheet(isPresented: .init(
            get: { spotReducer.showingAddBoxDialog },
            set: { newValue in
                Task {
                    await spotReducer.send(action: .setShowingAddBoxDialog(newValue))
                }
            }
        )) {
            addBoxSheet
        }
        .alert("Box Error", isPresented: .constant(spotReducer.boxesError != nil)) {
            Button("OK") {
                // Error will be cleared by reducer
            }
        } message: {
            if let error = spotReducer.boxesError {
                Text(error)
            }
        }
        .task {
            await spotReducer.send(action: .loadBoxes(spot: spot))
        }
    }

    private var addBoxSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Box Label", text: .init(
                        get: { spotReducer.newBoxLabel },
                        set: { newValue in
                            Task {
                                await spotReducer.send(action: .setNewBoxLabel(newValue))
                            }
                        }
                    ))
                        .textInputAutocapitalization(.words)
                    TextField("QR Code", text: .init(
                        get: { spotReducer.newBoxQRCode },
                        set: { newValue in
                            Task {
                                await spotReducer.send(action: .setNewBoxQRCode(newValue))
                            }
                        }
                    ))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("Box Information")
                }
            }
            .navigationTitle("New Box")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        Task {
                            await spotReducer.send(action: .setShowingAddBoxDialog(false))
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            await spotReducer.send(action: .addBox(
                                label: spotReducer.newBoxLabel,
                                qrCode: spotReducer.newBoxQRCode,
                                spot: spot
                            ))
                        }
                    }
                    .disabled(spotReducer.newBoxLabel.isEmpty || spotReducer.newBoxQRCode.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct EditSpotSheet: View {
    let spot: SpotDTO
    @State var spotReducer: Reducer<SpotListReducer>

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Spot Name", text: .init(
                        get: { spotReducer.editSpotName },
                        set: { newValue in
                            Task {
                                await spotReducer.send(action: .setEditSpotName(newValue))
                            }
                        }
                    ))
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
                            await spotReducer.send(action: .updateSpot(id: spot.id, name: spotReducer.editSpotName))
                            dismiss()
                        }
                    }
                    .disabled(spotReducer.editSpotName.isEmpty || spotReducer.editSpotName == spot.name)
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
