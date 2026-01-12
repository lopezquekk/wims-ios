// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import SwiftData

@available(iOS 17, *)
public let sharedModelContainer: ModelContainer = {
    let schema = Schema([
        Building.self,
        Room.self,
        Spot.self,
        Box.self,
        Item.self
    ])

    // Use explicit URL to avoid "Unable to determine Bundle Name" error in tests
    let url = URL.documentsDirectory.appending(path: "Wims.sqlite")
    let modelConfiguration = ModelConfiguration(
        schema: schema,
        url: url,
        cloudKitDatabase: .none
    )

    do {
        return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}()
