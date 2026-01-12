//
//  BuildingRepository.swift
//  Wims
//
//  Created by Camilo Lopez on 12/29/25.
//

import Foundation
import SwiftData

@available(iOS 17, *)
public protocol SwiftDataRepository {
    var modelContainer: ModelContainer { get }
}

@available(iOS 17, *)
public extension SwiftDataRepository {
    func background<T: Sendable>(
        priority: TaskPriority = .utility,
        _ work: @Sendable @escaping (ModelContext) throws -> T
    ) async throws -> T {

        let container = modelContainer

        return try await Task.detached(priority: priority) {
            let context = ModelContext(container)
            return try work(context)
        }.value
    }
}

@available(iOS 17, *)
public protocol BuildingRepository: Sendable, SwiftDataRepository {
    func fetchAll() async throws -> [BuildingDTO]
    func create(name: String) async throws -> BuildingDTO
    func update(id: UUID, name: String) async throws -> BuildingDTO
    func delete(id: UUID) async throws
}

@available(iOS 17, *)
public protocol RoomRepository: Sendable, SwiftDataRepository {
    func fetch(in building: BuildingDTO) async throws -> [RoomDTO]
    func create(name: String, in building: BuildingDTO) async throws -> RoomDTO
    func update(id: UUID, name: String) async throws -> RoomDTO
    func delete(id: UUID) async throws
}

@available(iOS 17, *)
public protocol SpotRepository: Sendable, SwiftDataRepository {
    func fetch(in room: RoomDTO) async throws -> [SpotDTO]
    func create(name: String, in room: RoomDTO) async throws -> SpotDTO
    func update(id: UUID, name: String) async throws -> SpotDTO
    func delete(id: UUID) async throws
}

@available(iOS 17, *)
public protocol BoxRepository: Sendable, SwiftDataRepository {
    func fetchAll() async throws -> [BoxDTO]
    func fetch(in spot: SpotDTO) async throws -> [BoxDTO]
    func fetch(byQRCode qr: String) async throws -> BoxDTO?
    func create(label: String, qrCode: String, in spot: SpotDTO) async throws -> BoxDTO
    func update(id: UUID, label: String, qrCode: String) async throws -> BoxDTO
    func delete(id: UUID) async throws
}

@available(iOS 17, *)
public protocol ItemRepository: Sendable, SwiftDataRepository {
    func fetchAll() async throws -> [ItemDTO]
    func fetch(in box: BoxDTO) async throws -> [ItemDTO]
    func create(
        name: String,
        notes: String?,
        imageData: Data?,
        in box: BoxDTO
    ) async throws -> ItemDTO
    func update(id: UUID, name: String, notes: String?, imageData: Data?) async throws -> ItemDTO
    func delete(id: UUID) async throws
}

