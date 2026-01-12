//
//  BoxListView.swift
//  Wims
//
//  Created by Camilo Lopez on 1/11/26.
//

import PersistencyLayer
import SwiftUI

struct BoxListView: View {
    @State private var viewModel: BoxListViewModel
    @State private var showingQRScanner = false
    @State private var qrCodeInput = ""

    init(viewModel: BoxListViewModel) {
        self._viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            boxesList
                .navigationTitle("Boxes")
                .searchable(text: $viewModel.searchText, prompt: "Search boxes")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        scanButton
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
                    await viewModel.loadAll()
                }
        }
        .sheet(isPresented: $showingQRScanner) {
            qrScannerSheet
        }
    }

    // MARK: - Subviews

    private var boxesList: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading boxes...")
            } else if viewModel.filteredBoxes.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(viewModel.filteredBoxes) { box in
                        NavigationLink {
                            BoxDetailView(box: box)
                        } label: {
                            BoxRowView(box: box)
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
            Label("No Boxes Found", systemImage: "shippingbox")
        } description: {
            if viewModel.searchText.isEmpty {
                Text("Create boxes by adding them to spots in Buildings")
            } else {
                Text("No boxes match your search")
            }
        } actions: {
            if !viewModel.searchText.isEmpty {
                Button("Clear Search") {
                    viewModel.searchText = ""
                }
            }
        }
    }

    private var scanButton: some View {
        Button {
            showingQRScanner = true
        } label: {
            Label("Scan QR", systemImage: "qrcode.viewfinder")
        }
    }

    private var qrScannerSheet: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("QR Code", text: $qrCodeInput)
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
                        showingQRScanner = false
                        qrCodeInput = ""
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Search") {
                        Task {
                            await viewModel.searchBox(byQRCode: qrCodeInput)
                            showingQRScanner = false
                            qrCodeInput = ""
                        }
                    }
                    .disabled(qrCodeInput.isEmpty)
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
        viewModel: BoxListViewModel(
            boxRepository: BoxRepositoryImpl(
                container: sharedModelContainer
            )
        )
    )
}
