//
//  ContentView.swift
//  Wims
//
//  Created by Camilo Lopez on 12/29/25.
//

import SwiftUI
import SwiftData
import PersistencyLayer
internal import Combine

@MainActor
@Observable
final class ContentViewModel {

    private let buildingRepository: BuildingRepository

    var buildings: [BuildingDTO] = []

    init(buildingRepository: BuildingRepository) {
        self.buildingRepository = buildingRepository
    }

    func load() async {
        do {
            buildings = try await buildingRepository.fetchAll()
        } catch {
            // aquí puedes manejar error (toast, alert, etc.)
            print("Error fetching buildings:", error)
        }
    }

    func addBuilding(name: String) async {
        do {
            let building = try await buildingRepository.create(name: name)
            buildings.append(building)
        } catch {
            print("Error creating building:", error)
        }
    }

    func delete(at offsets: IndexSet) {
        buildings.remove(atOffsets: offsets)
        // ⚠️ opcional: delegar delete real al repo
    }
}

struct ContentView: View {

    @State private var viewModel = ContentViewModel(buildingRepository: BuildingRepositoryImpl(container: sharedModelContainer))

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(viewModel.buildings) { item in
                    NavigationLink {
                        Text(item.createdAt, format: .dateTime)
                    } label: {
                        Text(item.createdAt, format: .dateTime)
                    }
                }
                .onDelete { offsets in
                    Task {
                        viewModel.delete(at: offsets)
                    }
                }
            }
            .toolbar {
                ToolbarItem {
                    Button {
                        Task {
                            await viewModel.addBuilding(name: "Demo Building")
                        }
                    } label: {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("Select an item")
        }.task {
            await viewModel.load()
        }
    }
}

#Preview {
    ContentView()
}
