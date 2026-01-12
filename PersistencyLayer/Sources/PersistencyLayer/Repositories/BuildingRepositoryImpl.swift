

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

    public func update(id: UUID, name: String) async throws -> BuildingDTO {
        try await background { context in
            let descriptor = FetchDescriptor<Building>(
                predicate: #Predicate { $0.id == id }
            )
            guard let building = try context.fetch(descriptor).first else {
                throw RepositoryError.notFound
            }
            building.name = name
            try context.save()
            return building.toDTO()
        }
    }

    public func delete(id: UUID) async throws {
        try await background { context in
            let descriptor = FetchDescriptor<Building>(
                predicate: #Predicate { $0.id == id }
            )
            guard let building = try context.fetch(descriptor).first else {
                throw RepositoryError.notFound
            }
            context.delete(building)
            try context.save()
        }
    }
}

public enum RepositoryError: Error {
    case notFound
    case invalidData
}
