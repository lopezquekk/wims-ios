//
//  Box.swift
//  Wims
//
//  Created by Camilo Lopez on 12/29/25.
//

import Foundation
import SwiftData

@Model
final class Box {

    @Attribute(.unique)
    var id: UUID

    var label: String
    var qrCode: String
    var createdAt: Date

    var spot: Spot?

    @Relationship(deleteRule: .cascade)
    var items: [Item] = []

    init(
        id: UUID = UUID(),
        label: String,
        qrCode: String,
        spot: Spot? = nil
    ) {
        self.id = id
        self.label = label
        self.qrCode = qrCode
        self.spot = spot
        self.createdAt = .now
    }
}
