//
//  Building.swift
//  Wims
//
//  Created by Camilo Lopez on 12/29/25.
//

import Foundation
import SwiftData

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

