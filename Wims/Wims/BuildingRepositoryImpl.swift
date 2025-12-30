//
//  BuildingRepositoryImpl.swift
//  Wims
//
//  Created by Camilo Lopez on 12/29/25.
//

import SwiftData
import Foundation

actor BoxRepositoryImpl: BoxRepository {

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Read
    func fetch(in spot: Spot) throws -> [Box] {
        let descriptor = FetchDescriptor<Box>(
            predicate: #Predicate { $0.spot?.id == spot.id }
        )
        return try context.fetch(descriptor)
    }

    func fetch(byQRCode qr: String) throws -> Box? {
        let descriptor = FetchDescriptor<Box>(
            predicate: #Predicate { $0.qrCode == qr }
        )
        return try context.fetch(descriptor).first
    }

    // MARK: - Create
    func create(
        label: String,
        qrCode: String,
        in spot: Spot
    ) throws -> Box {

        let box = Box(
            label: label,
            qrCode: qrCode,
            spot: spot
        )

        context.insert(box)
        try context.save()
        return box
    }
}

actor BuildingRepositoryImpl: BuildingRepository {

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetchAll() throws -> [Building] {
        let descriptor = FetchDescriptor<Building>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        return try context.fetch(descriptor)
    }

    func create(name: String) throws -> Building {
        let building = Building(name: name)
        context.insert(building)
        try context.save()
        return building
    }
}


actor RoomRepositoryImpl: RoomRepository {

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetch(in building: Building) throws -> [Room] {
        let descriptor = FetchDescriptor<Room>(
            predicate: #Predicate { $0.building?.id == building.id },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return try context.fetch(descriptor)
    }

    func create(name: String, in building: Building) throws -> Room {
        let room = Room(name: name, building: building)
        context.insert(room)
        try context.save()
        return room
    }
}

actor SpotRepositoryImpl: SpotRepository {

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetch(in room: Room) throws -> [Spot] {
        let descriptor = FetchDescriptor<Spot>(
            predicate: #Predicate { $0.room?.id == room.id },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return try context.fetch(descriptor)
    }

    func create(name: String, in room: Room) throws -> Spot {
        let spot = Spot(name: name, room: room)
        context.insert(spot)
        try context.save()
        return spot
    }
}

actor ItemRepositoryImpl: ItemRepository {

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func fetch(in box: Box) throws -> [Item] {
        let descriptor = FetchDescriptor<Item>(
            predicate: #Predicate { $0.box?.id == box.id },
            sortBy: [SortDescriptor(\.createdAt)]
        )
        return try context.fetch(descriptor)
    }

    func create(
        name: String,
        notes: String?,
        imageData: Data?,
        in box: Box
    ) throws -> Item {

        let item = Item(
            name: name,
            notes: notes,
            imageData: imageData,
            box: box
        )

        context.insert(item)
        try context.save()
        return item
    }
}
