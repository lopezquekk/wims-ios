//
//  Building.swift
//  Wims
//
//  Created by Camilo Lopez on 12/29/25.
//

import Foundation
import SwiftData

@available(iOS 17, *)
@Model
final class Building {

    @Attribute(.unique)
    var id: UUID

    var name: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade)
    var rooms: [Room] = []

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
        self.createdAt = .now
    }
}

@available(iOS 17, *)
extension Building {
    func toDTO() -> BuildingDTO {
        BuildingDTO(
            id: id,
            name: name,
            createdAt: Date()
        )
    }
}

public struct BuildingDTO: Identifiable, Sendable, Hashable {
    public let id: UUID
    public let name: String
    public let createdAt: Date

    public init(id: UUID, name: String, createdAt: Date) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
    }
}

extension BuildingDTO {
    @available(iOS 17, *)
    init(model: Building) {
        self.id = model.id
        self.name = model.name
        self.createdAt = model.createdAt
    }
}
