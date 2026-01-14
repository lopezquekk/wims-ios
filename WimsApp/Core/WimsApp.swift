//
//  WimsApp.swift
//  Wims
//
//  Created by Camilo Lopez on 12/29/25.
//

import FactoryKit
import PersistencyLayer
import SwiftData
import SwiftUI

@main
struct WimsApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(Container.shared.modelContainer())
    }
}
