# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Wims (Where Is My Stuff)** is an iOS application for tracking items and their physical locations using a hierarchical organization system: Buildings → Rooms → Spots → Boxes → Items. The app features QR code scanning for quick box lookup and a SwiftUI interface with tab-based navigation.

## Build & Test Commands

### iOS App (Xcode)
```bash
# Open the Xcode project
open Wims/Wims.xcodeproj

# Build from command line
xcodebuild -project Wims/Wims.xcodeproj -scheme Wims -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run tests
xcodebuild test -project Wims/Wims.xcodeproj -scheme Wims -destination 'platform=iOS Simulator,name=iPhone 16'
```

### Swift Packages

```bash
# Build PersistencyLayer package
cd PersistencyLayer
swift build

# Run PersistencyLayer tests
swift test

# Build SwiftDataQuery package
cd SwiftDataQuery
swift build
swift test
```

### Running Specific Tests

```bash
# Run specific test in package
swift test --filter PersistencyLayerTests.testFetchAllBuildings

# Run specific test class
swift test --filter RepositoryDeleteTests
```

## Architecture Overview

### Modular Structure

The project uses **Swift Package Manager** to separate concerns into modules:

- **Wims/** (Main iOS app) - SwiftUI views, view models, navigation
- **PersistencyLayer/** (SPM Package) - SwiftData entities, repositories, DTOs
- **SwiftDataQuery/** (SPM Package) - Generic SwiftData query utilities

### Data Model Hierarchy

```
Building (1)
    ↓ cascade delete
Room (many)
    ↓ cascade delete
Spot (many)
    ↓ cascade delete
Box (many)
    ↓ cascade delete
Item (many)
```

**Critical Pattern**: All relationships use `@Relationship(deleteRule: .cascade)`. Deleting a parent entity automatically deletes all children.

### Entity & DTO Pattern

Each domain entity has **two representations**:

1. **SwiftData Model** (internal to PersistencyLayer):
   - Annotated with `@Model`
   - Contains relationships and persistence logic
   - Private to the persistence layer

2. **DTO (Data Transfer Object)** (public API):
   - Plain Swift struct marked `Sendable` and `Hashable`
   - Flattened representation with computed location paths
   - Used by ViewModels and Views
   - Example: `BoxDTO` includes `buildingName`, `roomName`, `spotName`

### Repository Pattern

All data access goes through **actor-based repositories**:

```swift
// Protocol defines interface
public protocol BuildingRepository: SwiftDataRepository {
    func fetchAll() async throws -> [BuildingDTO]
    func create(name: String) async throws -> BuildingDTO
    func update(id: UUID, name: String) async throws -> BuildingDTO
    func delete(id: UUID) async throws
}

// Implementation is an Actor for thread safety
public actor BuildingRepositoryImpl: BuildingRepository {
    public let modelContainer: ModelContainer
    // ...methods
}
```

**Key Repositories**:
- `BuildingRepository` - Manages buildings
- `RoomRepository` - Scoped to parent building
- `SpotRepository` - Scoped to parent room
- `BoxRepository` - All boxes, by spot, or by QR code
- `ItemRepository` - All items or scoped to box

### Concurrency Model

**Thread Safety Rules**:
- All repositories are `actor`s (inherently thread-safe)
- Repository operations run off MainActor via `background()` helper
- ViewModels are `@MainActor` (all UI state mutations on main thread)
- Communication uses `async/await` with `Sendable` DTOs

**Background Helper** (in `SwiftDataRepository` protocol):
```swift
public func background<T: Sendable>(
    priority: TaskPriority = .utility,
    _ work: @Sendable @escaping (ModelContext) throws -> T
) async throws -> T
```

### MVVM Architecture

**Pattern**: Views → ViewModels → Repositories → SwiftData

**ViewModel Patterns**:
- Newer code uses `@Observable` macro (BuildingListViewModel)
- Older code uses `@ObservableObject` + `@Published` (BoxListViewModel, ItemListViewModel)
- All VMs are `@MainActor` for UI thread safety
- VMs perform async operations and update published state

**View Structure**:
- `MainTabView` - Root with 4 tabs (Boxes, Items, Buildings, Settings)
- NavigationStack for linear flows
- NavigationSplitView for master-detail (Buildings hierarchy)
- Sheet presentations for add/edit dialogs

## Important Implementation Details

### Adding New Entities

When adding a new entity to the data model:

1. Create SwiftData `@Model` in `PersistencyLayer/Sources/PersistencyLayer/Entities/`
2. Add `@Relationship(deleteRule: .cascade)` for child collections
3. Create corresponding DTO struct (must be `Sendable` and `Hashable`)
4. Add entity to `sharedModelContainer` schema in `PersistencyLayer.swift`
5. Create repository protocol and actor implementation in `Repositories/`
6. Inject repository into ViewModels via constructor
7. Create ViewModel (use `@Observable` for new code)
8. Create SwiftUI views

### SwiftData Container Setup

The shared container is initialized in `PersistencyLayer/Sources/PersistencyLayer/PersistencyLayer.swift`:

```swift
public let sharedModelContainer: ModelContainer = {
    let schema = Schema([
        Building.self, Room.self, Spot.self, Box.self, Item.self
    ])
    let modelConfiguration = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: false
    )
    return try ModelContainer(for: schema, configurations: [modelConfiguration])
}()
```

**For Testing**: Use `isStoredInMemoryOnly: true` to create isolated test containers.

### Error Handling

Repositories throw `RepositoryError`:
```swift
public enum RepositoryError: Error {
    case notFound
    case invalidData
}
```

ViewModels catch errors and expose via `errorMessage` property:
```swift
var errorMessage: String?

func addBuilding(name: String) async {
    do {
        let building = try await buildingRepository.create(name: name)
        buildings.append(building)
    } catch {
        errorMessage = "Error: \(error.localizedDescription)"
    }
}
```

Views display errors using SwiftUI alerts bound to `errorMessage`.

### QR Code Features

`BoxRepository` supports QR code lookup:
```swift
func fetch(byQRCode: String) async throws -> BoxDTO?
```

QR codes are stored in the `qrCode` property of Box entities. The `BoxListView` includes a QR scanner sheet for quick lookup.

## Testing Guidelines

### Test Framework

Uses **Swift Testing** (new framework, not XCTest):
- Annotations: `@Suite` and `@Test`
- Assertions: `#expect(condition)` instead of `XCTAssert`
- Async support: `async throws` test methods

### Test Categories

1. **Performance Tests** - Measure operation timing with `ContinuousClock`
   - Creating 10K buildings < 2s
   - Fetching 500 buildings < 2s
   - 50 concurrent operations < 3s

2. **Concurrency Tests** - Verify thread safety and actor behavior
   - Background operations run off MainActor
   - MainActor not blocked during repo operations

3. **CRUD Tests** - Functional tests for all entity operations

4. **Cascade Delete Tests** - Verify parent deletion removes children

### Test Setup Pattern

```swift
private func createInMemoryContainer() throws -> ModelContainer {
    let schema = Schema([
        Building.self, Room.self, Spot.self, Box.self, Item.self
    ])
    let configuration = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: true
    )
    return try ModelContainer(for: schema, configurations: [configuration])
}
```

## Platform Requirements

- **Minimum iOS**: 17.0 (required for SwiftData)
- **Minimum macOS**: 14.0 (for package compatibility)
- **Swift**: 6.0+ toolchain
- **Xcode**: Latest version with iOS 17+ SDK

## Dependencies

External dependencies are managed via Swift Package Manager:
- **Algorithms** (Apple) - Used in main app

Both `PersistencyLayer` and `SwiftDataQuery` have **no external dependencies**.

## Code Organization Patterns

### File Structure
```
PersistencyLayer/
├── Sources/PersistencyLayer/
│   ├── Entities/              # @Model classes (5 files)
│   ├── Repositories/          # Protocols + Actor implementations
│   └── PersistencyLayer.swift # Container setup
└── Tests/
    ├── PersistencyLayerTests.swift      # Main test suite
    └── RepositoryDeleteTests.swift      # Cascade deletion tests

Wims/Wims/
├── Views/              # SwiftUI views (15 files)
├── ViewModels/         # Observable view models (5 files)
└── WimsApp.swift       # App entry point
```

### Naming Conventions
- **Entities**: Singular nouns (e.g., `Building`, `Room`, `Box`)
- **DTOs**: Entity name + "DTO" suffix (e.g., `BuildingDTO`)
- **Repositories**: Entity name + "Repository" protocol, "RepositoryImpl" implementation
- **ViewModels**: View name + "ViewModel" (e.g., `BuildingListViewModel`)
- **Views**: Descriptive names ending in "View" (e.g., `BuildingListView`, `BoxDetailView`)

### Common Patterns

**Fetching scoped children**:
```swift
// Fetch rooms within a specific building
let rooms = try await roomRepository.fetch(in: buildingId)

// Fetch spots within a specific room
let spots = try await spotRepository.fetch(in: roomId)
```

**Cascade deletion flow**:
```swift
// Deleting a building automatically deletes:
// - All rooms in that building
// - All spots in those rooms
// - All boxes in those spots
// - All items in those boxes
try await buildingRepository.delete(id: buildingId)
```

**ViewModel loading pattern**:
```swift
@MainActor
func load() async {
    isLoading = true
    defer { isLoading = false }

    do {
        buildings = try await buildingRepository.fetchAll()
    } catch {
        errorMessage = "Failed to load: \(error.localizedDescription)"
    }
}
```

**View loading with .task modifier**:
```swift
.task {
    await viewModel.load()
}
```
