//
//  BoxesForSpotView.swift
//  Wims
//
//  Created by Camilo Lopez on 1/11/26.
//

import PersistencyLayer
import SwiftUI

struct BoxesForSpotView: View {
    let spot: SpotDTO

    @StateObject private var viewModel: BoxListViewModel
    @State private var showingAddDialog = false
    @State private var newBoxLabel = ""
    @State private var newBoxQRCode = ""

    init(spot: SpotDTO) {
        self.spot = spot
        self._viewModel = StateObject(wrappedValue: BoxListViewModel(
            boxRepository: BoxRepositoryImpl(container: sharedModelContainer)
        ))
    }

    var body: some View {
        boxesList
            .navigationTitle("Boxes")
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
                await viewModel.load(for: spot)
            }
            .sheet(isPresented: $showingAddDialog) {
                addBoxSheet
            }
    }

    // MARK: - Subviews

    private var boxesList: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading boxes...")
            } else if viewModel.boxes.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(viewModel.boxes) { box in
                        NavigationLink {
                            BoxForSpotDetailView(box: box, viewModel: viewModel)
                        } label: {
                            BoxForSpotRowView(box: box)
                        }
                    }
                    .onDelete { offsets in
                        Task {
                            await viewModel.deleteBoxes(at: offsets)
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Boxes", systemImage: "shippingbox")
        } description: {
            Text("Add your first box to get started")
        } actions: {
            Button("Add Box") {
                showingAddDialog = true
            }
        }
    }

    private var addButton: some View {
        Button {
            showingAddDialog = true
        } label: {
            Label("Add Box", systemImage: "plus")
        }
    }

    private var addBoxSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Box Label", text: $newBoxLabel)
                        .textInputAutocapitalization(.words)
                    TextField("QR Code", text: $newBoxQRCode)
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
                        showingAddDialog = false
                        newBoxLabel = ""
                        newBoxQRCode = ""
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Task {
                            await viewModel.addBox(label: newBoxLabel, qrCode: newBoxQRCode, in: spot)
                            showingAddDialog = false
                            newBoxLabel = ""
                            newBoxQRCode = ""
                        }
                    }
                    .disabled(newBoxLabel.isEmpty || newBoxQRCode.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Supporting Views

struct BoxForSpotRowView: View {
    let box: BoxDTO

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(box.label)
                .font(.headline)
            HStack {
                Text("QR: \(box.qrCode)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(box.createdAt, format: .dateTime)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct BoxForSpotDetailView: View {
    let box: BoxDTO
    @ObservedObject var viewModel: BoxListViewModel
    @State private var showingEditSheet = false

    var body: some View {
        List {
            Section("Details") {
                LabeledContent("Label", value: box.label)
                LabeledContent("QR Code", value: box.qrCode)
                LabeledContent("Created") {
                    Text(box.createdAt, format: .dateTime)
                }
            }

            Section("Items") {
                NavigationLink {
                    ItemsForBoxView(box: box)
                } label: {
                    Label("Manage Items", systemImage: "tray")
                }
            }
        }
        .navigationTitle(box.label)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    showingEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditBoxSheet(box: box, viewModel: viewModel)
        }
    }
}

struct EditBoxSheet: View {
    let box: BoxDTO
    @ObservedObject var viewModel: BoxListViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var boxLabel: String
    @State private var boxQRCode: String

    init(box: BoxDTO, viewModel: BoxListViewModel) {
        self.box = box
        self.viewModel = viewModel
        self._boxLabel = State(initialValue: box.label)
        self._boxQRCode = State(initialValue: box.qrCode)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Box Label", text: $boxLabel)
                        .textInputAutocapitalization(.words)
                    TextField("QR Code", text: $boxQRCode)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("Box Information")
                } footer: {
                    Text("Enter new values for this box")
                }
            }
            .navigationTitle("Edit Box")
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
                            await viewModel.updateBox(id: box.id, label: boxLabel, qrCode: boxQRCode)
                            dismiss()
                        }
                    }
                    .disabled(boxLabel.isEmpty || boxQRCode.isEmpty ||
                             (boxLabel == box.label && boxQRCode == box.qrCode))
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        BoxesForSpotView(
            spot: SpotDTO(
                id: UUID(),
                name: "Sample Spot",
                roomID: UUID(),
                createdAt: Date()
            )
        )
    }
}
