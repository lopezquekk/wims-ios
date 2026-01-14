//
//  DependencyContainer.swift
//  Wims
//
//  Created by Claude Code on 1/13/26.
//

import FactoryKit
import Foundation
import PersistencyLayer
import SwiftData

// MARK: - Core Dependencies

extension Container {
    /// Provides the shared ModelContainer for SwiftData persistence.
    /// Scope: Singleton - single instance shared across the app.
    var modelContainer: Factory<ModelContainer> {
        self { sharedModelContainer }
            .singleton
    }
}

// MARK: - Building Feature

extension Container {
    /// Provides the repository for Building CRUD operations.
    /// Scope: Singleton - repositories are actors, safe to share.
    var buildingRepository: Factory<BuildingRepository> {
        self { BuildingRepositoryImpl(container: self.modelContainer()) }
            .singleton
    }

    /// Provides a new BuildingListReducer instance for view state management.
    /// Scope: Unique - new instance per view to isolate state.
    var buildingListReducer: Factory<BuildingListReducer> {
        self { @MainActor in BuildingListReducer(buildingRepository: self.buildingRepository()) }
            .unique
    }
}

// MARK: - Room Feature

extension Container {
    /// Provides the repository for Room CRUD operations.
    /// Scope: Singleton - repositories are actors, safe to share.
    var roomRepository: Factory<RoomRepository> {
        self { RoomRepositoryImpl(container: self.modelContainer()) }
            .singleton
    }

    /// Provides a new RoomListReducer instance for view state management.
    /// Scope: Unique - new instance per view to isolate state.
    var roomListReducer: Factory<RoomListReducer> {
        self { @MainActor in RoomListReducer(roomRepository: self.roomRepository()) }
            .unique
    }
}

// MARK: - Spot Feature

extension Container {
    /// Provides the repository for Spot CRUD operations.
    /// Scope: Singleton - repositories are actors, safe to share.
    var spotRepository: Factory<SpotRepository> {
        self { SpotRepositoryImpl(container: self.modelContainer()) }
            .singleton
    }

    /// Provides a new SpotListReducer instance for view state management.
    /// Scope: Unique - new instance per view to isolate state.
    /// Note: SpotListReducer manages both spots and boxes within spots.
    var spotListReducer: Factory<SpotListReducer> {
        self { @MainActor in
            SpotListReducer(
                spotRepository: self.spotRepository(),
                boxRepository: self.boxRepository()
            )
        }
        .unique
    }
}

// MARK: - Box Feature

extension Container {
    /// Provides the repository for Box CRUD operations and QR code lookup.
    /// Scope: Singleton - repositories are actors, safe to share.
    var boxRepository: Factory<BoxRepository> {
        self { BoxRepositoryImpl(container: self.modelContainer()) }
            .singleton
    }

    /// Provides a new BoxListReducer instance for view state management.
    /// Scope: Unique - new instance per view to isolate state.
    var boxListReducer: Factory<BoxListReducer> {
        self { @MainActor in BoxListReducer(boxRepository: self.boxRepository()) }
            .unique
    }
}

// MARK: - Item Feature

extension Container {
    /// Provides the repository for Item CRUD operations.
    /// Scope: Singleton - repositories are actors, safe to share.
    var itemRepository: Factory<ItemRepository> {
        self { ItemRepositoryImpl(container: self.modelContainer()) }
            .singleton
    }

    /// Provides a new ItemListReducer instance for view state management.
    /// Scope: Unique - new instance per view to isolate state.
    var itemListReducer: Factory<ItemListReducer> {
        self { @MainActor in ItemListReducer(itemRepository: self.itemRepository()) }
            .unique
    }
}

// MARK: - Preview & Testing Support

#if DEBUG
extension Container {
    /// Sets up the container for SwiftUI previews.
    /// Uses the shared model container. For isolated testing, mock the repositories instead.
    /// Example: Container.shared.buildingRepository.register { MockBuildingRepository() }
    static func setupForPreviews() {
        // Previews use the shared model container by default.
        // This method is here for consistency with the pattern, but no setup is needed.
        // To use mock data, register mock repositories instead.
    }

    /// Sets up the container for unit tests with isolated state.
    /// Resets all registrations. Register mock repositories after calling this.
    static func setupForTesting() {
        shared.reset()
    }
}
#endif
