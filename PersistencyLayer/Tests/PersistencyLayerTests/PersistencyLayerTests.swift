import Foundation
@testable import PersistencyLayer
import SwiftData
import Testing

@Suite("PersistencyLayer Tests")
struct PersistencyLayerTests {
    // MARK: - Performance Tests

    @available(iOS 17, *)
    @Test("Performance: Create 10000 buildings")
    func testCreateBuildingsPerformance() async throws {
        let container = try createInMemoryContainer()
        let repository = BuildingRepositoryImpl(container: container)

        let startTime = ContinuousClock.now

        for i in 0..<10_000 {
            _ = try await repository.create(name: "Building \(i)")
        }

        let duration = startTime.duration(to: .now)

        // Verificar que la operación tome menos de 2 segundos
        #expect(duration < .seconds(2), "Creating 100 buildings should take less than 5 seconds, took \(duration)")
    }

    @available(iOS 17, *)
    @Test("Performance: Fetch all buildings after creating many")
    func testFetchAllPerformance() async throws {
        let container = try createInMemoryContainer()
        let repository = BuildingRepositoryImpl(container: container)

        // Crear 500 buildings
        for i in 0..<500 {
            _ = try await repository.create(name: "Building \(i)")
        }

        let startTime = ContinuousClock.now
        let buildings = try await repository.fetchAll()
        let duration = startTime.duration(to: .now)

        #expect(buildings.count == 500)
        #expect(duration < .seconds(2), "Fetching 500 buildings should take less than 2 seconds, took \(duration)")
    }

    @available(iOS 17, *)
    @Test("Performance: Concurrent operations")
    func testConcurrentOperationsPerformance() async throws {
        let container = try createInMemoryContainer()
        let repository = BuildingRepositoryImpl(container: container)

        let startTime = ContinuousClock.now

        // Ejecutar 50 operaciones concurrentes
        try await withThrowingTaskGroup(of: BuildingDTO.self) { group in
            for i in 0..<50 {
                group.addTask {
                    try await repository.create(name: "Concurrent Building \(i)")
                }
            }

            var count = 0
            for try await _ in group {
                count += 1
            }
            #expect(count == 50)
        }

        let duration = startTime.duration(to: .now)
        #expect(duration < .seconds(3), "50 concurrent operations should take less than 3 seconds, took \(duration)")
    }

    // MARK: - MainActor Tests

    @available(iOS 17, *)
    @Test("Repository operations do not block MainActor")
    @MainActor
    func testDoesNotBlockMainActor() async throws {
        let container = try createInMemoryContainer()
        let repository = BuildingRepositoryImpl(container: container)

        var mainActorTaskCompleted = false

        // Iniciar una operación larga en el repository
        let repositoryTask = Task {
            for i in 0..<100 {
                _ = try await repository.create(name: "Building \(i)")
            }
        }

        // Verificar que el MainActor puede seguir ejecutando tareas
        let mainActorTask = Task { @MainActor in
            // Esta tarea debería completarse rápidamente a pesar de la operación del repository
            try await Task.sleep(for: .milliseconds(100))
            mainActorTaskCompleted = true
        }

        try await mainActorTask.value
        #expect(mainActorTaskCompleted, "MainActor task should complete while repository is working")

        try await repositoryTask.value
    }

    @available(iOS 17, *)
    @Test("Background operations run off main thread")
    func testBackgroundOperationsOffMainThread() async throws {
        let container = try createInMemoryContainer()
        let repository = BuildingRepositoryImpl(container: container)

        // Crear un building y verificar en qué thread se ejecuta
        _ = try await repository.create(name: "Test Building")

        // Usar el método background directamente para verificar
        let wasOnMainThread = try await repository.background { _ in
            Thread.isMainThread
        }

        #expect(!wasOnMainThread, "Background operations should not run on main thread")
    }

    @available(iOS 17, *)
    @Test("Multiple concurrent operations maintain MainActor responsiveness")
    @MainActor
    func testMainActorResponsivenessUnderLoad() async throws {
        let container = try createInMemoryContainer()
        let repository = BuildingRepositoryImpl(container: container)

        var mainActorCounter = 0

        // Iniciar múltiples operaciones pesadas
        let heavyTask = Task {
            try await withThrowingTaskGroup(of: Void.self) { group in
                for i in 0..<50 {
                    group.addTask {
                        _ = try await repository.create(name: "Heavy Building \(i)")
                        _ = try await repository.fetchAll()
                    }
                }
                try await group.waitForAll()
            }
        }

        // Simular actualizaciones de UI en el MainActor
        let uiTask = Task { @MainActor in
            for _ in 0..<20 {
                try await Task.sleep(for: .milliseconds(50))
                mainActorCounter += 1
            }
        }

        try await uiTask.value
        #expect(mainActorCounter == 20, "MainActor should be able to increment counter 20 times while repository works")

        try await heavyTask.value
    }

    // MARK: - Functional Tests

    @available(iOS 17, *)
    @Test("Create and fetch buildings")
    func testCreateAndFetch() async throws {
        let container = try createInMemoryContainer()
        let repository = BuildingRepositoryImpl(container: container)

        let building1 = try await repository.create(name: "Building 1")
        let building2 = try await repository.create(name: "Building 2")

        let allBuildings = try await repository.fetchAll()

        #expect(allBuildings.count == 2)
        #expect(allBuildings.contains(where: { $0.id == building1.id }))
        #expect(allBuildings.contains(where: { $0.id == building2.id }))
    }

    @available(iOS 17, *)
    @Test("Buildings are sorted by creation date")
    func testBuildingsAreSorted() async throws {
        let container = try createInMemoryContainer()
        let repository = BuildingRepositoryImpl(container: container)

        let building1 = try await repository.create(name: "First")
        try await Task.sleep(for: .milliseconds(100))
        let building2 = try await repository.create(name: "Second")
        try await Task.sleep(for: .milliseconds(100))
        let building3 = try await repository.create(name: "Third")

        let allBuildings = try await repository.fetchAll()

        #expect(allBuildings.count == 3)
        #expect(allBuildings[0].id == building1.id)
        #expect(allBuildings[1].id == building2.id)
        #expect(allBuildings[2].id == building3.id)
    }

    // MARK: - Helper Methods

    @available(iOS 17, *)
    private func createInMemoryContainer() throws -> ModelContainer {
        let schema = Schema([
            Building.self,
            Room.self,
            Spot.self,
            Box.self,
            Item.self
        ])
        // Don't specify schema in ModelConfiguration to avoid bundle resolution issues
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
