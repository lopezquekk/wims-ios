//
//  Box.swift
//  Wims
//
//  Created by Camilo Lopez on 12/29/25.
//

import Foundation
import SwiftData

@available(iOS 17, *)
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

struct BoxDTO: Identifiable, Sendable {
    let id: UUID
    let label: String
    let qrCode: String
    let spotID: UUID
    let createdAt: Date
}

extension BoxDTO {
    @available(iOS 17, *)
    init(model: Box) {
        self.id = model.id
        self.label = model.label
        self.qrCode = model.qrCode
        self.spotID = model.spot?.id ?? UUID()
        self.createdAt = model.createdAt
    }
}
