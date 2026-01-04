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
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
