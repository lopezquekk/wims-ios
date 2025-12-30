//
//  Item.swift
//  Wims
//
//  Created by Camilo Lopez on 12/29/25.
//

import Foundation
import SwiftData

@Model
final class Item {

    @Attribute(.unique)
    var id: UUID

    var name: String
    var notes: String?
    var imageData: Data?
    var createdAt: Date

    var box: Box?

    init(
        id: UUID = UUID(),
        name: String,
        notes: String? = nil,
        imageData: Data? = nil,
        box: Box? = nil
    ) {
        self.id = id
        self.name = name
        self.notes = notes
        self.imageData = imageData
        self.box = box
        self.createdAt = .now
    }
}
