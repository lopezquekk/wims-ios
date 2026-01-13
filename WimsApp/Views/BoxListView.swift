//
//  BoxListView.swift
//  Wims
//
//  Created by Camilo Lopez on 1/11/26.
//

import PersistencyLayer
import SwiftUI

struct BoxListView: View {
    @State private var boxReducer: Reducer<BoxListViewModel>

    init(boxRepository: BoxRepository) {
        self._boxReducer = State(
            wrappedValue: .init(
                reducer: BoxListViewModel(boxRepository: boxRepository),
                initialState: .init()
            )
        )
    }

    var body: some View {
        NavigationStack {
            boxesList
                .navigationTitle("Boxes")
                .searchable(
                    text: .init(
                        get: { boxReducer.searchText },
                        set: { newValue in
                            Task {
                                await boxReducer.send(action: .setSearchText(newValue))
                            }
                        }
                    ),
                    prompt: "Search boxes"
                )
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        scanButton
                    }
                }
                .alert("Error", isPresented: .constant(boxReducer.errorMessage != nil)) {
                    Button("OK") {
                        // Error will be cleared by reducer
                    }
                } message: {
                    if let error = boxReducer.errorMessage {
                        Text(error)
                    }
                }
                .task {
                    await boxReducer.send(action: .loadAll)
                }
        }
        .sheet(isPresented: .init(
            get: { boxReducer.showingQRScanner },
            set: { newValue in
                Task {
                    await boxReducer.send(action: .setShowingQRScanner(newValue))
                }
            }
        )) {
            qrScannerSheet
        }
    }

    // MARK: - Subviews

    private var boxesList: some View {
        Group {
            if boxReducer.isLoading {
                ProgressView("Loading boxes...")
            } else if boxReducer.filteredBoxes.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(boxReducer.filteredBoxes) { box in
                        NavigationLink {
                            BoxDetailView(box: box)
                        } label: {
                            BoxRowView(box: box)
                        }
                    }
                    .onDelete { offsets in
                        Task {
                            await boxReducer.send(action: .deleteBoxes(offsets: offsets))
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Boxes Found", systemImage: "shippingbox")
        } description: {
            if boxReducer.searchText.isEmpty {
                Text("Create boxes by adding them to spots in Buildings")
            } else {
                Text("No boxes match your search")
            }
        } actions: {
            if !boxReducer.searchText.isEmpty {
                Button("Clear Search") {
                    Task {
                        await boxReducer.send(action: .setSearchText(""))
                    }
                }
            }
        }
    }

    private var scanButton: some View {
        Button {
            Task {
                await boxReducer.send(action: .setShowingQRScanner(true))
            }
        } label: {
            Label("Scan QR", systemImage: "qrcode.viewfinder")
        }
    }

    private var qrScannerSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("QR Code", text: .init(
                        get: { boxReducer.qrCodeInput },
                        set: { newValue in
                            Task {
                                await boxReducer.send(action: .setQRCodeInput(newValue))
                            }
                        }
                    ))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } header: {
                    Text("Enter or Scan QR Code")
                } footer: {
                    Text("Enter the QR code manually or use a QR scanner")
                }
            }
            .navigationTitle("Find Box")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        Task {
                            await boxReducer.send(action: .setShowingQRScanner(false))
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Search") {
                        Task {
                            await boxReducer.send(action: .searchByQR(qrCode: boxReducer.qrCodeInput))
                        }
                    }
                    .disabled(boxReducer.qrCodeInput.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Supporting Views

struct BoxRowView: View {
    let box: BoxDTO

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(box.label)
                .font(.headline)

            HStack(spacing: 4) {
                Image(systemName: "mappin.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.blue)
                Text(box.locationPath)
                    .font(.caption)
                    .foregroundStyle(.blue)
                    .lineLimit(1)
            }

            HStack {
                Label(box.qrCode, systemImage: "qrcode")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(box.createdAt, format: .dateTime)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct BoxDetailView: View {
    let box: BoxDTO

    @State private var itemViewModel: ItemListViewModel

    init(box: BoxDTO) {
        self.box = box
        self._itemViewModel = State(wrappedValue: ItemListViewModel(
            itemRepository: ItemRepositoryImpl(container: sharedModelContainer)
        ))
    }

    var body: some View {
        List {
            Section("Details") {
                LabeledContent("Label", value: box.label)
                LabeledContent("QR Code", value: box.qrCode)
                LabeledContent("Created") {
                    Text(box.createdAt, format: .dateTime)
                }
            }

            Section("Location") {
                HStack {
                    Image(systemName: "building.2.fill")
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Building")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(box.buildingName)
                            .font(.body)
                    }
                }

                HStack {
                    Image(systemName: "door.left.hand.open")
                        .foregroundStyle(.green)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Room")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(box.roomName)
                            .font(.body)
                    }
                }

                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundStyle(.orange)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Spot")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(box.spotName)
                            .font(.body)
                            .fontWeight(.semibold)
                    }
                }
            }

            Section {
                if itemViewModel.isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else if itemViewModel.items.isEmpty {
                    Text("No items in this box")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                } else {
                    ForEach(itemViewModel.items) { item in
                        NavigationLink {
                            ItemForBoxDetailView(item: item, viewModel: itemViewModel)
                        } label: {
                            HStack(spacing: 12) {
                                if let imageData = item.imageData,
                                   let uiImage = UIImage(data: imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 50, height: 50)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                } else {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 50, height: 50)
                                        .overlay {
                                            Image(systemName: "photo")
                                                .foregroundStyle(.secondary)
                                        }
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.name)
                                        .font(.body)
                                        .fontWeight(.medium)
                                    if let notes = item.notes, !notes.isEmpty {
                                        Text(notes)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                            }
                        }
                    }
                }
            } header: {
                Text("Items")
            }
        }
        .navigationTitle(box.label)
        .task {
            await itemViewModel.load(for: box)
        }
    }
}

// MARK: - Preview

#Preview {
    BoxListView(
        boxRepository: BoxRepositoryImpl(
            container: sharedModelContainer
        )
    )
}
