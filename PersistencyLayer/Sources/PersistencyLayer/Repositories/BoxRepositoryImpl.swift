
import SwiftData
import Foundation

@available(iOS 17, *)
public actor BoxRepositoryImpl: BoxRepository {

    public let modelContainer: ModelContainer

    public init(container: ModelContainer) {
        self.modelContainer = container
    }

    public func fetchAll() async throws -> [BoxDTO] {
        return try await background { context in
            let descriptor = FetchDescriptor<Box>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            return try context.fetch(descriptor).map { BoxDTO(model: $0) }
        }
    }

    public func fetch(in spot: SpotDTO) async throws -> [BoxDTO] {
        let spotID = spot.id
        return try await background { context in
            let descriptor = FetchDescriptor<Box>(
                predicate: #Predicate { $0.spot?.id == spotID },
                sortBy: [SortDescriptor(\.createdAt)]
            )
            return try context.fetch(descriptor).map { BoxDTO(model: $0) }
        }
    }

    public func fetch(byQRCode qr: String) async throws -> BoxDTO? {
        try await background { context in
            let descriptor = FetchDescriptor<Box>(
                predicate: #Predicate { $0.qrCode == qr }
            )
            guard let box = try context.fetch(descriptor).first else {
                return nil
            }
            return BoxDTO(model: box)
        }
    }

    public func create(label: String, qrCode: String, in spot: SpotDTO) async throws -> BoxDTO {
        let spotID = spot.id
        return try await background { context in
            let spotDescriptor = FetchDescriptor<Spot>(
                predicate: #Predicate { $0.id == spotID }
            )
            guard let spotModel = try context.fetch(spotDescriptor).first else {
                throw RepositoryError.notFound
            }

            let box = Box(label: label, qrCode: qrCode, spot: spotModel)
            context.insert(box)
            try context.save()
            return BoxDTO(model: box)
        }
    }

    public func update(id: UUID, label: String, qrCode: String) async throws -> BoxDTO {
        try await background { context in
            let descriptor = FetchDescriptor<Box>(
                predicate: #Predicate { $0.id == id }
            )
            guard let box = try context.fetch(descriptor).first else {
                throw RepositoryError.notFound
            }
            box.label = label
            box.qrCode = qrCode
            try context.save()
            return BoxDTO(model: box)
        }
    }

    public func delete(id: UUID) async throws {
        try await background { context in
            let descriptor = FetchDescriptor<Box>(
                predicate: #Predicate { $0.id == id }
            )
            guard let box = try context.fetch(descriptor).first else {
                throw RepositoryError.notFound
            }
            context.delete(box)
            try context.save()
        }
    }
}
