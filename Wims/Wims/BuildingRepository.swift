//
//  BuildingRepository.swift
//  Wims
//
//  Created by Camilo Lopez on 12/29/25.
//

import Foundation

protocol BuildingRepository {
    func fetchAll() async throws -> [Building]
    func create(name: String) async throws -> Building
}

protocol RoomRepository {
    func fetch(in building: Building) async throws -> [Room]
    func create(name: String, in building: Building) async throws -> Room
}

protocol SpotRepository {
    func fetch(in room: Room) async throws -> [Spot]
    func create(name: String, in room: Room) async throws -> Spot
}

protocol BoxRepository {
    func fetch(in spot: Spot) async throws -> [Box]
    func fetch(byQRCode qr: String) async throws -> Box?
    func create(label: String, qrCode: String, in spot: Spot) async throws -> Box
}

protocol ItemRepository {
    func fetch(in box: Box) async throws -> [Item]
    func create(
        name: String,
        notes: String?,
        imageData: Data?,
        in box: Box
    ) async throws -> Item
}

