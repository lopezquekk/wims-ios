//
//  Room.swift
//  Wims
//
//  Created by Camilo Lopez on 12/29/25.
//

import Foundation
import SwiftData

@available(iOS 17, *)
@Model
final class Room {

    @Attribute(.unique)
    var id: UUID

    var name: String
    var createdAt: Date

    var building: Building?

    @Relationship(deleteRule: .cascade)
    var spots: [Spot] = []

    init(id: UUID = UUID(), name: String, building: Building? = nil) {
        self.id = id
        self.name = name
        self.building = building
        self.createdAt = .now
    }
}

struct RoomDTO: Identifiable, Sendable {
    let id: UUID
    let name: String
    let buildingID: UUID
    let createdAt: Date
}

extension RoomDTO {
    @available(iOS 17, *)
    init(model: Room) {
        self.id = model.id
        self.name = model.name
        self.buildingID = model.building?.id ?? UUID()
        self.createdAt = model.createdAt
    }
}
