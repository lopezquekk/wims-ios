//
//  WimsApp.swift
//  Wims
//
//  Created by Camilo Lopez on 12/29/25.
//

import SwiftUI
import SwiftData
import PersistencyLayer

@main
struct WimsApp: App {

    var body: some Scene {
        WindowGroup {
            MainTabView(
                buildingRepository: BuildingRepositoryImpl(container: sharedModelContainer),
                boxRepository: BoxRepositoryImpl(container: sharedModelContainer),
                itemRepository: ItemRepositoryImpl(container: sharedModelContainer)
            )
        }
        .modelContainer(sharedModelContainer)
    }
}
