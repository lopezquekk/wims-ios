// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import SwiftData

@available(iOS 17, *)
@propertyWrapper
@MainActor
public final class SwiftDataQueryDTO<Model: PersistentModel, DTO: Sendable>: ObservableObject {

    @Published public var wrappedValue: [DTO] = []

    private let actor: SwiftDataBackgroundActor
    private let descriptor: FetchDescriptor<Model>
    private let map: @Sendable (Model) -> DTO

    @available(iOS 17, *)
    init(
        container: ModelContainer,
        descriptor: FetchDescriptor<Model>,
        map: @escaping @Sendable (Model) -> DTO
    ) {
        self.actor = SwiftDataBackgroundActor(modelContainer: container)
        self.descriptor = descriptor
        self.map = map
        Task { await refresh() }
    }

    func refresh() async {
        do {
            let result = try await actor.fetch(
                descriptor: descriptor,
                map: map
            )
            wrappedValue = result
        } catch {
            wrappedValue = []
        }
    }
}

@available(iOS 17, *)
@ModelActor
actor SwiftDataBackgroundActor {

    func fetch<Model: PersistentModel, DTO: Sendable>(
        descriptor: FetchDescriptor<Model>,
        map: @Sendable (Model) -> DTO
    ) throws -> [DTO] {
        let models = try modelContext.fetch(descriptor)
        return models.map(map)
    }
}
