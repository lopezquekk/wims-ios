

import SwiftData
import Foundation

@available(iOS 17, *)
public actor BuildingRepositoryImpl: BuildingRepository {

    public let modelContainer: ModelContainer

    public init(container: ModelContainer) {
        self.modelContainer = container
    }

    public func fetchAll() async throws -> [BuildingDTO] {
        try await background { context in
            let descriptor = FetchDescriptor<Building>(
                sortBy: [SortDescriptor(\.createdAt)]
            )
            return try context.fetch(descriptor).map { $0.toDTO() }
        }
    }

    public func create(name: String) async throws -> BuildingDTO {
        try await background { context in
            let building = Building(name: name)
            context.insert(building)
            try context.save()
            return building.toDTO()
        }
    }
}
