
import SwiftData
import Foundation

@available(iOS 17, *)
public actor RoomRepositoryImpl: RoomRepository {

    public let modelContainer: ModelContainer

    public init(container: ModelContainer) {
        self.modelContainer = container
    }

    public func fetch(in building: BuildingDTO) async throws -> [RoomDTO] {
        let buildingID = building.id
        return try await background { context in
            let descriptor = FetchDescriptor<Room>(
                predicate: #Predicate { $0.building?.id == buildingID },
                sortBy: [SortDescriptor(\.createdAt)]
            )
            return try context.fetch(descriptor).map { RoomDTO(model: $0) }
        }
    }

    public func create(name: String, in building: BuildingDTO) async throws -> RoomDTO {
        let buildingID = building.id
        return try await background { context in
            let buildingDescriptor = FetchDescriptor<Building>(
                predicate: #Predicate { $0.id == buildingID }
            )
            guard let buildingModel = try context.fetch(buildingDescriptor).first else {
                throw RepositoryError.notFound
            }

            let room = Room(name: name, building: buildingModel)
            context.insert(room)
            try context.save()
            return RoomDTO(model: room)
        }
    }

    public func update(id: UUID, name: String) async throws -> RoomDTO {
        try await background { context in
            let descriptor = FetchDescriptor<Room>(
                predicate: #Predicate { $0.id == id }
            )
            guard let room = try context.fetch(descriptor).first else {
                throw RepositoryError.notFound
            }
            room.name = name
            try context.save()
            return RoomDTO(model: room)
        }
    }

    public func delete(id: UUID) async throws {
        try await background { context in
            let descriptor = FetchDescriptor<Room>(
                predicate: #Predicate { $0.id == id }
            )
            guard let room = try context.fetch(descriptor).first else {
                throw RepositoryError.notFound
            }
            context.delete(room)
            try context.save()
        }
    }
}
