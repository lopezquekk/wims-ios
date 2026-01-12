// The Swift Programming Language
// https://docs.swift.org/swift-book

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
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

    do {
        return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
        fatalError("Could not create ModelContainer: \(error)")
    }
}()
