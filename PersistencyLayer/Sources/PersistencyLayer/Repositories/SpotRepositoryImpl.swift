
import SwiftData
import Foundation

@available(iOS 17, *)
public actor SpotRepositoryImpl: SpotRepository {

    public let modelContainer: ModelContainer

    public init(container: ModelContainer) {
        self.modelContainer = container
    }

    public func fetch(in room: RoomDTO) async throws -> [SpotDTO] {
        let roomID = room.id
        return try await background { context in
            let descriptor = FetchDescriptor<Spot>(
                predicate: #Predicate { $0.room?.id == roomID },
                sortBy: [SortDescriptor(\.createdAt)]
            )
            return try context.fetch(descriptor).map { SpotDTO(model: $0) }
        }
    }

    public func create(name: String, in room: RoomDTO) async throws -> SpotDTO {
        let roomID = room.id
        return try await background { context in
            let roomDescriptor = FetchDescriptor<Room>(
                predicate: #Predicate { $0.id == roomID }
            )
            guard let roomModel = try context.fetch(roomDescriptor).first else {
                throw RepositoryError.notFound
            }

            let spot = Spot(name: name, room: roomModel)
            context.insert(spot)
            try context.save()
            return SpotDTO(model: spot)
        }
    }

    public func update(id: UUID, name: String) async throws -> SpotDTO {
        try await background { context in
            let descriptor = FetchDescriptor<Spot>(
                predicate: #Predicate { $0.id == id }
            )
            guard let spot = try context.fetch(descriptor).first else {
                throw RepositoryError.notFound
            }
            spot.name = name
            try context.save()
            return SpotDTO(model: spot)
        }
    }

    public func delete(id: UUID) async throws {
        try await background { context in
            let descriptor = FetchDescriptor<Spot>(
                predicate: #Predicate { $0.id == id }
            )
            guard let spot = try context.fetch(descriptor).first else {
                throw RepositoryError.notFound
            }
            context.delete(spot)
            try context.save()
        }
    }
}
