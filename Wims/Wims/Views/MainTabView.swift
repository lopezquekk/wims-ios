//
//  MainTabView.swift
//  Wims
//
//  Created by Camilo Lopez on 1/11/26.
//

import PersistencyLayer
import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    // Repository instances
    private let buildingRepository: BuildingRepository
    private let boxRepository: BoxRepository
    private let itemRepository: ItemRepository

    init(
        buildingRepository: BuildingRepository,
        boxRepository: BoxRepository,
        itemRepository: ItemRepository
    ) {
        self.buildingRepository = buildingRepository
        self.boxRepository = boxRepository
        self.itemRepository = itemRepository
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            BoxListView(
                viewModel: BoxListViewModel(boxRepository: boxRepository)
            )
            .tabItem {
                Label("Boxes", systemImage: "shippingbox")
            }
            .tag(0)

            ItemListView(
                viewModel: ItemListViewModel(itemRepository: itemRepository)
            )
            .tabItem {
                Label("Items", systemImage: "list.bullet.rectangle")
            }
            .tag(1)

            BuildingListView(
                viewModel: BuildingListViewModel(buildingRepository: buildingRepository)
            )
            .tabItem {
                Label("Buildings", systemImage: "building.2")
            }
            .tag(2)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
    }
}

#Preview {
    MainTabView(
        buildingRepository: BuildingRepositoryImpl(container: sharedModelContainer),
        boxRepository: BoxRepositoryImpl(container: sharedModelContainer),
        itemRepository: ItemRepositoryImpl(container: sharedModelContainer)
    )
}
