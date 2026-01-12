import Foundation
import SwiftData

@available(iOS 17, *)
public actor ItemRepositoryImpl: ItemRepository {
    public let modelContainer: ModelContainer

    public init(container: ModelContainer) {
        self.modelContainer = container
    }

    public func fetchAll() async throws -> [ItemDTO] {
        try await background { context in
            let descriptor = FetchDescriptor<Item>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            return try context.fetch(descriptor).map { ItemDTO(model: $0) }
        }
    }

    public func fetch(in box: BoxDTO) async throws -> [ItemDTO] {
        let boxID = box.id
        return try await background { context in
            let descriptor = FetchDescriptor<Item>(
                predicate: #Predicate { $0.box?.id == boxID },
                sortBy: [SortDescriptor(\.createdAt)]
            )
            return try context.fetch(descriptor).map { ItemDTO(model: $0) }
        }
    }

    public func create(
        name: String,
        notes: String?,
        imageData: Data?,
        in box: BoxDTO
    ) async throws -> ItemDTO {
        let boxID = box.id
        return try await background { context in
            let boxDescriptor = FetchDescriptor<Box>(
                predicate: #Predicate { $0.id == boxID }
            )
            guard let boxModel = try context.fetch(boxDescriptor).first else {
                throw RepositoryError.notFound
            }

            let item = Item(itemName: name, notes: notes, imageData: imageData, box: boxModel)
            context.insert(item)
            try context.save()
            return ItemDTO(model: item)
        }
    }

    public func update(id: UUID, name: String, notes: String?, imageData: Data?) async throws -> ItemDTO {
        try await background { context in
            let descriptor = FetchDescriptor<Item>(
                predicate: #Predicate { $0.id == id }
            )
            guard let item = try context.fetch(descriptor).first else {
                throw RepositoryError.notFound
            }
            item.itemName = name
            item.notes = notes
            item.imageData = imageData
            try context.save()
            return ItemDTO(model: item)
        }
    }

    public func delete(id: UUID) async throws {
        try await background { context in
            let descriptor = FetchDescriptor<Item>(
                predicate: #Predicate { $0.id == id }
            )
            guard let item = try context.fetch(descriptor).first else {
                throw RepositoryError.notFound
            }
            context.delete(item)
            try context.save()
        }
    }
}
