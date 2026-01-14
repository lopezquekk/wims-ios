//
//  MainTabView.swift
//  Wims
//
//  Created by Camilo Lopez on 1/11/26.
//

import FactoryKit
import PersistencyLayer
import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            BoxListView()
                .tabItem {
                    Label("Boxes", systemImage: "shippingbox")
                }
                .tag(0)

            ItemListView()
                .tabItem {
                    Label("Items", systemImage: "list.bullet.rectangle")
                }
                .tag(1)

            BuildingListView()
                .tabItem {
                    Label("Buildings", systemImage: "building.2")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
    }
}

#Preview {
    Container.setupForPreviews()
    return MainTabView()
}
