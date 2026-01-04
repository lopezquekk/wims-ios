//
//  Item.swift
//  Wims
//
//  Created by Camilo Lopez on 12/29/25.
//

import Foundation
import SwiftData

@available(iOS 17, *)
@Model
public final class Item {

    @Attribute(.unique)
    public var id: UUID

    public var itemName: String
    public var notes: String?
    public var imageData: Data?
    public var createdAt: Date

    var box: Box?

    init(
        id: UUID = UUID(),
        itemName: String,
        notes: String? = nil,
        imageData: Data? = nil,
        box: Box? = nil
    ) {
        self.id = id
        self.itemName = itemName
        self.notes = notes
        self.imageData = imageData
        self.box = box
        self.createdAt = .now
    }
}

public struct ItemDTO: Identifiable, Sendable {
    public let id: UUID
    public let name: String
    public let notes: String?
    public let imageData: Data?
    public let boxID: UUID
    public let createdAt: Date
    
    public init(id: UUID, name: String, notes: String?, imageData: Data?, boxID: UUID, createdAt: Date) {
        self.id = id
        self.name = name
        self.notes = notes
        self.imageData = imageData
        self.boxID = boxID
        self.createdAt = createdAt
    }
}

extension ItemDTO {
    @available(iOS 17, *)
    init(model: Item) {
        self.id = model.id
        self.name = model.itemName
        self.notes = model.notes
        self.imageData = model.imageData
        self.boxID = model.box?.id ?? UUID()
        self.createdAt = model.createdAt
    }
}
