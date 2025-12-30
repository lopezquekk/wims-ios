//
//  Spot.swift
//  Wims
//
//  Created by Camilo Lopez on 12/29/25.
//

import Foundation
import SwiftData

@Model
final class Spot {

    @Attribute(.unique)
    var id: UUID

    var name: String
    var createdAt: Date

    var room: Room?

    @Relationship(deleteRule: .cascade)
    var boxes: [Box] = []

    init(id: UUID = UUID(), name: String, room: Room? = nil) {
        self.id = id
        self.name = name
        self.room = room
        self.createdAt = .now
    }
}
