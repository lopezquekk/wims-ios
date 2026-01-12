//
//  EditBuildingSheet.swift
//  Wims
//
//  Created by Camilo Lopez on 1/11/26.
//

import SwiftUI
import PersistencyLayer

struct EditBuildingSheet: View {
    let building: BuildingDTO

    @Environment(\.dismiss) private var dismiss
    @State private var buildingName: String
    @State private var viewModel: BuildingListViewModel

    init(building: BuildingDTO) {
        self.building = building
        self._buildingName = State(initialValue: building.name)
        self._viewModel = State(initialValue: BuildingListViewModel(
            buildingRepository: BuildingRepositoryImpl(container: sharedModelContainer)
        ))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Building Name", text: $buildingName)
                        .textInputAutocapitalization(.words)
                } header: {
                    Text("Building Information")
                } footer: {
                    Text("Enter a new name for this building")
                }
            }
            .navigationTitle("Edit Building")
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
                            await viewModel.updateBuilding(id: building.id, name: buildingName)
                            dismiss()
                        }
                    }
                    .disabled(buildingName.isEmpty || buildingName == building.name)
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
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    EditBuildingSheet(
        building: BuildingDTO(
            id: UUID(),
            name: "Sample Building",
            createdAt: Date()
        )
    )
}
