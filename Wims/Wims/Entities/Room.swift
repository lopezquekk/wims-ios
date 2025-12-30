//
//  Room.swift
//  Wims
//
//  Created by Camilo Lopez on 12/29/25.
//

import Foundation
import SwiftData

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
