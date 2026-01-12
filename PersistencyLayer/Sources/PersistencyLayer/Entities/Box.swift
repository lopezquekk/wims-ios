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

public struct BoxDTO: Identifiable, Sendable, Hashable {
    public let id: UUID
    public let label: String
    public let qrCode: String
    public let spotID: UUID
    public let createdAt: Date

    // Location information
    public let spotName: String
    public let roomName: String
    public let buildingName: String

    public init(
        id: UUID,
        label: String,
        qrCode: String,
        spotID: UUID,
        createdAt: Date,
        spotName: String,
        roomName: String,
        buildingName: String
    ) {
        self.id = id
        self.label = label
        self.qrCode = qrCode
        self.spotID = spotID
        self.createdAt = createdAt
        self.spotName = spotName
        self.roomName = roomName
        self.buildingName = buildingName
    }

    public var locationPath: String {
        "\(buildingName) → \(roomName) → \(spotName)"
    }
}

extension BoxDTO {
    @available(iOS 17, *)
    init(model: Box) {
        self.id = model.id
        self.label = model.label
        self.qrCode = model.qrCode
        self.spotID = model.spot?.id ?? UUID()
        self.createdAt = model.createdAt

        // Extract location information
        self.spotName = model.spot?.name ?? "Unknown Spot"
        self.roomName = model.spot?.room?.name ?? "Unknown Room"
        self.buildingName = model.spot?.room?.building?.name ?? "Unknown Building"
    }
}
