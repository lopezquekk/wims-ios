//
//  EditBuildingSheet.swift
//  Wims
//
//  Created by Camilo Lopez on 1/11/26.
//

import PersistencyLayer
import SwiftUI

struct EditBuildingSheet: View {
    let building: BuildingDTO
    @State var buildingReducer: Reducer<BuildingListReducer>

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Building Name", text: .init(
                        get: { buildingReducer.editBuildingName },
                        set: { newValue in
                            Task {
                                await buildingReducer.send(action: .setEditBuildingName(newValue))
                            }
                        }
                    ))
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
                            await buildingReducer.send(action: .updateBuilding(id: building.id, name: buildingReducer.editBuildingName))
                            dismiss()
                        }
                    }
                    .disabled(buildingReducer.editBuildingName.isEmpty || buildingReducer.editBuildingName == building.name)
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
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    @Previewable @State var reducer = Reducer(
        reducer: BuildingListReducer(
            buildingRepository: BuildingRepositoryImpl(container: sharedModelContainer)
        ),
        initialState: .init()
    )

    EditBuildingSheet(
        building: BuildingDTO(
            id: UUID(),
            name: "Sample Building",
            createdAt: Date()
        ),
        buildingReducer: reducer
    )
}
