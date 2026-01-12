//
//  WimsTests.swift
//  WimsTests
//
//  Created by Camilo Lopez on 12/29/25.
//

import Testing
import SwiftData
@testable import Wims

@Suite("Repository Tests")
struct RepositoryTests {

    let container: ModelContainer

    init() throws {
        let schema = Schema([
            Building.self,
            Room.self,
            Spot.self,
            Box.self,
            Item.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [configuration])
    }

    // MARK: - Building Repository Tests

    @Test("Create and fetch buildings")
    func testBuildingRepository() async throws {
        let repo = BuildingRepositoryImpl(modelContainer: container)

        // Create a building
        let building = try await repo.create(name: "Test Building")
        #expect(building.name == "Test Building")

        // Fetch all buildings
        let buildings = try await repo.fetchAll()
        #expect(buildings.count == 1)
        #expect(buildings.first?.name == "Test Building")
    }

    @Test("Create multiple buildings and verify order")
    func testMultipleBuildingsOrder() async throws {
        let repo = BuildingRepositoryImpl(modelContainer: container)

        let building1 = try await repo.create(name: "Building A")
        let building2 = try await repo.create(name: "Building B")
        let building3 = try await repo.create(name: "Building C")

        let buildings = try await repo.fetchAll()
        #expect(buildings.count == 3)
        // Should be ordered by createdAt
        #expect(buildings[0].name == "Building A")
        #expect(buildings[1].name == "Building B")
        #expect(buildings[2].name == "Building C")
    }

    // MARK: - Room Repository Tests

    @Test("Create and fetch rooms in building")
    func testRoomRepository() async throws {
        let buildingRepo = BuildingRepositoryImpl(modelContainer: container)
        let roomRepo = RoomRepositoryImpl(modelContainer: container)

        // Create a building
        let building = try await buildingRepo.create(name: "Main Building")
        let buildingId = ModelIdentifier(building)

        // Create rooms
        let room1 = try await roomRepo.create(name: "Room 101", in: buildingId)
        let room2 = try await roomRepo.create(name: "Room 102", in: buildingId)

        #expect(room1.name == "Room 101")
        #expect(room2.name == "Room 102")

        // Fetch rooms
        let rooms = try await roomRepo.fetch(in: buildingId)
        #expect(rooms.count == 2)
    }

    @Test("Rooms are isolated per building")
    func testRoomsIsolatedPerBuilding() async throws {
        let buildingRepo = BuildingRepositoryImpl(modelContainer: container)
        let roomRepo = RoomRepositoryImpl(modelContainer: container)

        let building1 = try await buildingRepo.create(name: "Building 1")
        let building2 = try await buildingRepo.create(name: "Building 2")

        let building1Id = ModelIdentifier(building1)
        let building2Id = ModelIdentifier(building2)

        _ = try await roomRepo.create(name: "B1 Room 1", in: building1Id)
        _ = try await roomRepo.create(name: "B1 Room 2", in: building1Id)
        _ = try await roomRepo.create(name: "B2 Room 1", in: building2Id)

        let building1Rooms = try await roomRepo.fetch(in: building1Id)
        let building2Rooms = try await roomRepo.fetch(in: building2Id)

        #expect(building1Rooms.count == 2)
        #expect(building2Rooms.count == 1)
    }

    // MARK: - Spot Repository Tests

    @Test("Create and fetch spots in room")
    func testSpotRepository() async throws {
        let buildingRepo = BuildingRepositoryImpl(modelContainer: container)
        let roomRepo = RoomRepositoryImpl(modelContainer: container)
        let spotRepo = SpotRepositoryImpl(modelContainer: container)

        let building = try await buildingRepo.create(name: "Building")
        let buildingId = ModelIdentifier(building)

        let room = try await roomRepo.create(name: "Room", in: buildingId)
        let roomId = ModelIdentifier(room)

        let spot1 = try await spotRepo.create(name: "Shelf A", in: roomId)
        let spot2 = try await spotRepo.create(name: "Shelf B", in: roomId)

        #expect(spot1.name == "Shelf A")
        #expect(spot2.name == "Shelf B")

        let spots = try await spotRepo.fetch(in: roomId)
        #expect(spots.count == 2)
    }

    // MARK: - Box Repository Tests

    @Test("Create and fetch boxes in spot")
    func testBoxRepository() async throws {
        let buildingRepo = BuildingRepositoryImpl(modelContainer: container)
        let roomRepo = RoomRepositoryImpl(modelContainer: container)
        let spotRepo = SpotRepositoryImpl(modelContainer: container)
        let boxRepo = BoxRepositoryImpl(modelContainer: container)

        let building = try await buildingRepo.create(name: "Building")
        let room = try await roomRepo.create(name: "Room", in: ModelIdentifier(building))
        let spot = try await spotRepo.create(name: "Spot", in: ModelIdentifier(room))
        let spotId = ModelIdentifier(spot)

        let box1 = try await boxRepo.create(label: "Box 1", qrCode: "QR001", in: spotId)
        let box2 = try await boxRepo.create(label: "Box 2", qrCode: "QR002", in: spotId)

        #expect(box1.label == "Box 1")
        #expect(box1.qrCode == "QR001")
        #expect(box2.label == "Box 2")

        let boxes = try await boxRepo.fetch(in: spotId)
        #expect(boxes.count == 2)
    }

    @Test("Fetch box by QR code")
    func testFetchBoxByQRCode() async throws {
        let buildingRepo = BuildingRepositoryImpl(modelContainer: container)
        let roomRepo = RoomRepositoryImpl(modelContainer: container)
        let spotRepo = SpotRepositoryImpl(modelContainer: container)
        let boxRepo = BoxRepositoryImpl(modelContainer: container)

        let building = try await buildingRepo.create(name: "Building")
        let room = try await roomRepo.create(name: "Room", in: ModelIdentifier(building))
        let spot = try await spotRepo.create(name: "Spot", in: ModelIdentifier(room))

        _ = try await boxRepo.create(label: "Box 1", qrCode: "UNIQUE_QR_123", in: ModelIdentifier(spot))

        let foundBox = try await boxRepo.fetch(byQRCode: "UNIQUE_QR_123")
        #expect(foundBox != nil)
        #expect(foundBox?.qrCode == "UNIQUE_QR_123")
        #expect(foundBox?.label == "Box 1")

        let notFoundBox = try await boxRepo.fetch(byQRCode: "NONEXISTENT")
        #expect(notFoundBox == nil)
    }

    // MARK: - Item Repository Tests

    @Test("Create and fetch items in box")
    func testItemRepository() async throws {
        let buildingRepo = BuildingRepositoryImpl(modelContainer: container)
        let roomRepo = RoomRepositoryImpl(modelContainer: container)
        let spotRepo = SpotRepositoryImpl(modelContainer: container)
        let boxRepo = BoxRepositoryImpl(modelContainer: container)
        let itemRepo = ItemRepositoryImpl(modelContainer: container)

        let building = try await buildingRepo.create(name: "Building")
        let room = try await roomRepo.create(name: "Room", in: ModelIdentifier(building))
        let spot = try await spotRepo.create(name: "Spot", in: ModelIdentifier(room))
        let box = try await boxRepo.create(label: "Box", qrCode: "QR123", in: ModelIdentifier(spot))
        let boxId = ModelIdentifier(box)

        let item1 = try await itemRepo.create(
            name: "Laptop",
            notes: "MacBook Pro 2021",
            imageData: nil,
            in: boxId
        )

        let item2 = try await itemRepo.create(
            name: "Mouse",
            notes: nil,
            imageData: nil,
            in: boxId
        )

        #expect(item1.name == "Laptop")
        #expect(item1.notes == "MacBook Pro 2021")
        #expect(item2.name == "Mouse")
        #expect(item2.notes == nil)

        let items = try await itemRepo.fetch(in: boxId)
        #expect(items.count == 2)
    }

    @Test("Item with image data")
    func testItemWithImageData() async throws {
        let buildingRepo = BuildingRepositoryImpl(modelContainer: container)
        let roomRepo = RoomRepositoryImpl(modelContainer: container)
        let spotRepo = SpotRepositoryImpl(modelContainer: container)
        let boxRepo = BoxRepositoryImpl(modelContainer: container)
        let itemRepo = ItemRepositoryImpl(modelContainer: container)

        let building = try await buildingRepo.create(name: "Building")
        let room = try await roomRepo.create(name: "Room", in: ModelIdentifier(building))
        let spot = try await spotRepo.create(name: "Spot", in: ModelIdentifier(room))
        let box = try await boxRepo.create(label: "Box", qrCode: "QR456", in: ModelIdentifier(spot))

        let testImageData = Data([0x01, 0x02, 0x03, 0x04])

        let item = try await itemRepo.create(
            name: "Photo",
            notes: "Test photo",
            imageData: testImageData,
            in: ModelIdentifier(box)
        )

        #expect(item.imageData != nil)
        #expect(item.imageData == testImageData)
    }

    // MARK: - Integration Tests

    @Test("Complete hierarchy workflow")
    func testCompleteHierarchy() async throws {
        let buildingRepo = BuildingRepositoryImpl(modelContainer: container)
        let roomRepo = RoomRepositoryImpl(modelContainer: container)
        let spotRepo = SpotRepositoryImpl(modelContainer: container)
        let boxRepo = BoxRepositoryImpl(modelContainer: container)
        let itemRepo = ItemRepositoryImpl(modelContainer: container)

        // Create hierarchy
        let building = try await buildingRepo.create(name: "Warehouse")
        let room = try await roomRepo.create(name: "Storage Room", in: ModelIdentifier(building))
        let spot = try await spotRepo.create(name: "Shelf A1", in: ModelIdentifier(room))
        let box = try await boxRepo.create(label: "Electronics", qrCode: "ELEC001", in: ModelIdentifier(spot))
        let item = try await itemRepo.create(
            name: "Cable",
            notes: "HDMI Cable 2m",
            imageData: nil,
            in: ModelIdentifier(box)
        )

        // Verify each level
        #expect(building.name == "Warehouse")
        #expect(room.name == "Storage Room")
        #expect(spot.name == "Shelf A1")
        #expect(box.label == "Electronics")
        #expect(item.name == "Cable")

        // Verify relationships work
        let foundBox = try await boxRepo.fetch(byQRCode: "ELEC001")
        #expect(foundBox?.label == "Electronics")

        let items = try await itemRepo.fetch(in: ModelIdentifier(box))
        #expect(items.count == 1)
        #expect(items.first?.name == "Cable")
    }
}
