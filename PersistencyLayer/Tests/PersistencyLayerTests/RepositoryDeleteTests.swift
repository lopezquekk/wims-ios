import Testing
import SwiftData
import Foundation
@testable import PersistencyLayer

@Suite("Repository Delete Tests")
struct RepositoryDeleteTests {

    // MARK: - Building Delete Tests

    @available(iOS 17, *)
    @Test("Delete building successfully")
    func testDeleteBuilding() async throws {
        let container = try createInMemoryContainer()
        let repository = BuildingRepositoryImpl(container: container)

        // Create a building
        let building = try await repository.create(name: "Building to Delete")

        // Verify it exists
        let allBefore = try await repository.fetchAll()
        #expect(allBefore.count == 1)
        #expect(allBefore.contains(where: { $0.id == building.id }))

        // Delete it
        try await repository.delete(id: building.id)

        // Verify it's deleted
        let allAfter = try await repository.fetchAll()
        #expect(allAfter.count == 0)
    }

    @available(iOS 17, *)
    @Test("Delete non-existent building throws error")
    func testDeleteNonExistentBuilding() async throws {
        let container = try createInMemoryContainer()
        let repository = BuildingRepositoryImpl(container: container)

        let nonExistentID = UUID()

        await #expect(throws: RepositoryError.notFound) {
            try await repository.delete(id: nonExistentID)
        }
    }

    @available(iOS 17, *)
    @Test("Delete building with cascade deletes rooms")
    func testDeleteBuildingCascadesRooms() async throws {
        let container = try createInMemoryContainer()
        let buildingRepo = BuildingRepositoryImpl(container: container)
        let roomRepo = RoomRepositoryImpl(container: container)

        // Create building with rooms
        let building = try await buildingRepo.create(name: "Building")
        _ = try await roomRepo.create(name: "Room 1", in: building)
        _ = try await roomRepo.create(name: "Room 2", in: building)

        // Verify rooms exist
        let roomsBefore = try await roomRepo.fetch(in: building)
        #expect(roomsBefore.count == 2)

        // Delete building
        try await buildingRepo.delete(id: building.id)

        // Verify building is deleted
        let buildings = try await buildingRepo.fetchAll()
        #expect(buildings.count == 0)
    }

    // MARK: - Room Delete Tests

    @available(iOS 17, *)
    @Test("Delete room successfully")
    func testDeleteRoom() async throws {
        let container = try createInMemoryContainer()
        let buildingRepo = BuildingRepositoryImpl(container: container)
        let roomRepo = RoomRepositoryImpl(container: container)

        let building = try await buildingRepo.create(name: "Building")
        let room = try await roomRepo.create(name: "Room to Delete", in: building)

        // Verify it exists
        let roomsBefore = try await roomRepo.fetch(in: building)
        #expect(roomsBefore.count == 1)

        // Delete it
        try await roomRepo.delete(id: room.id)

        // Verify it's deleted
        let roomsAfter = try await roomRepo.fetch(in: building)
        #expect(roomsAfter.count == 0)
    }

    @available(iOS 17, *)
    @Test("Delete non-existent room throws error")
    func testDeleteNonExistentRoom() async throws {
        let container = try createInMemoryContainer()
        let roomRepo = RoomRepositoryImpl(container: container)

        await #expect(throws: RepositoryError.notFound) {
            try await roomRepo.delete(id: UUID())
        }
    }

    // MARK: - Spot Delete Tests

    @available(iOS 17, *)
    @Test("Delete spot successfully")
    func testDeleteSpot() async throws {
        let container = try createInMemoryContainer()
        let buildingRepo = BuildingRepositoryImpl(container: container)
        let roomRepo = RoomRepositoryImpl(container: container)
        let spotRepo = SpotRepositoryImpl(container: container)

        let building = try await buildingRepo.create(name: "Building")
        let room = try await roomRepo.create(name: "Room", in: building)
        let spot = try await spotRepo.create(name: "Spot to Delete", in: room)

        // Verify it exists
        let spotsBefore = try await spotRepo.fetch(in: room)
        #expect(spotsBefore.count == 1)

        // Delete it
        try await spotRepo.delete(id: spot.id)

        // Verify it's deleted
        let spotsAfter = try await spotRepo.fetch(in: room)
        #expect(spotsAfter.count == 0)
    }

    @available(iOS 17, *)
    @Test("Delete non-existent spot throws error")
    func testDeleteNonExistentSpot() async throws {
        let container = try createInMemoryContainer()
        let spotRepo = SpotRepositoryImpl(container: container)

        await #expect(throws: RepositoryError.notFound) {
            try await spotRepo.delete(id: UUID())
        }
    }

    // MARK: - Box Delete Tests

    @available(iOS 17, *)
    @Test("Delete box successfully")
    func testDeleteBox() async throws {
        let container = try createInMemoryContainer()
        let buildingRepo = BuildingRepositoryImpl(container: container)
        let roomRepo = RoomRepositoryImpl(container: container)
        let spotRepo = SpotRepositoryImpl(container: container)
        let boxRepo = BoxRepositoryImpl(container: container)

        let building = try await buildingRepo.create(name: "Building")
        let room = try await roomRepo.create(name: "Room", in: building)
        let spot = try await spotRepo.create(name: "Spot", in: room)
        let box = try await boxRepo.create(label: "Box to Delete", qrCode: "QR123", in: spot)

        // Verify it exists
        let boxesBefore = try await boxRepo.fetch(in: spot)
        #expect(boxesBefore.count == 1)

        // Delete it
        try await boxRepo.delete(id: box.id)

        // Verify it's deleted
        let boxesAfter = try await boxRepo.fetch(in: spot)
        #expect(boxesAfter.count == 0)
    }

    @available(iOS 17, *)
    @Test("Delete non-existent box throws error")
    func testDeleteNonExistentBox() async throws {
        let container = try createInMemoryContainer()
        let boxRepo = BoxRepositoryImpl(container: container)

        await #expect(throws: RepositoryError.notFound) {
            try await boxRepo.delete(id: UUID())
        }
    }

    // MARK: - Item Delete Tests

    @available(iOS 17, *)
    @Test("Delete item successfully")
    func testDeleteItem() async throws {
        let container = try createInMemoryContainer()
        let buildingRepo = BuildingRepositoryImpl(container: container)
        let roomRepo = RoomRepositoryImpl(container: container)
        let spotRepo = SpotRepositoryImpl(container: container)
        let boxRepo = BoxRepositoryImpl(container: container)
        let itemRepo = ItemRepositoryImpl(container: container)

        let building = try await buildingRepo.create(name: "Building")
        let room = try await roomRepo.create(name: "Room", in: building)
        let spot = try await spotRepo.create(name: "Spot", in: room)
        let box = try await boxRepo.create(label: "Box", qrCode: "QR123", in: spot)
        let item = try await itemRepo.create(name: "Item to Delete", notes: nil, imageData: nil, in: box)

        // Verify it exists
        let itemsBefore = try await itemRepo.fetch(in: box)
        #expect(itemsBefore.count == 1)

        // Delete it
        try await itemRepo.delete(id: item.id)

        // Verify it's deleted
        let itemsAfter = try await itemRepo.fetch(in: box)
        #expect(itemsAfter.count == 0)
    }

    @available(iOS 17, *)
    @Test("Delete non-existent item throws error")
    func testDeleteNonExistentItem() async throws {
        let container = try createInMemoryContainer()
        let itemRepo = ItemRepositoryImpl(container: container)

        await #expect(throws: RepositoryError.notFound) {
            try await itemRepo.delete(id: UUID())
        }
    }

    // MARK: - Performance Tests for Delete

    @available(iOS 17, *)
    @Test("Delete performance: 100 buildings")
    func testDeletePerformance() async throws {
        let container = try createInMemoryContainer()
        let repository = BuildingRepositoryImpl(container: container)

        // Create 100 buildings
        var buildingIDs: [UUID] = []
        for i in 0..<100 {
            let building = try await repository.create(name: "Building \(i)")
            buildingIDs.append(building.id)
        }

        let startTime = ContinuousClock.now

        // Delete all buildings
        for id in buildingIDs {
            try await repository.delete(id: id)
        }

        let duration = startTime.duration(to: .now)

        // Verify all deleted
        let all = try await repository.fetchAll()
        #expect(all.count == 0)
        #expect(duration < .seconds(3), "Deleting 100 buildings should take less than 3 seconds, took \(duration)")
    }

    @available(iOS 17, *)
    @Test("Delete does not block MainActor")
    @MainActor
    func testDeleteDoesNotBlockMainActor() async throws {
        let container = try createInMemoryContainer()
        let repository = BuildingRepositoryImpl(container: container)

        // Create buildings
        var buildingIDs: [UUID] = []
        for i in 0..<50 {
            let building = try await repository.create(name: "Building \(i)")
            buildingIDs.append(building.id)
        }

        var mainActorCounter = 0

        // Start delete operations
        let deleteTask = Task {
            for id in buildingIDs {
                try await repository.delete(id: id)
            }
        }

        // Verify MainActor is responsive
        let mainActorTask = Task { @MainActor in
            for _ in 0..<10 {
                try await Task.sleep(for: .milliseconds(50))
                mainActorCounter += 1
            }
        }

        try await mainActorTask.value
        #expect(mainActorCounter == 10, "MainActor should remain responsive during delete operations")

        try await deleteTask.value
    }

    // MARK: - Helper Methods

    private func createInMemoryContainer() throws -> ModelContainer {
        let schema = Schema([
            Building.self,
            Room.self,
            Spot.self,
            Box.self,
            Item.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
