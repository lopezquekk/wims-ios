//
//  Spot.swift
//  Wims
//
//  Created by Camilo Lopez on 12/29/25.
//

import Foundation
import SwiftData

@available(iOS 17, *)
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

struct SpotDTO: Identifiable, Sendable {
    let id: UUID
    let name: String
    let roomID: UUID
    let createdAt: Date
}

extension SpotDTO {
    @available(iOS 17, *)
    init(model: Spot) {
        self.id = model.id
        self.name = model.name
        self.roomID = model.room?.id ?? UUID()
        self.createdAt = model.createdAt
    }
}
