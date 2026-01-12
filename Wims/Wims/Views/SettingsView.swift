//
//  SettingsView.swift
//  Wims
//
//  Created by Camilo Lopez on 1/11/26.
//

import SwiftUI

struct SettingsView: View {

    @AppStorage("appTheme") private var appTheme: AppTheme = .system
    @AppStorage("showImages") private var showImages = true
    @AppStorage("enableNotifications") private var enableNotifications = false

    var body: some View {
        NavigationStack {
            Form {
                appearanceSection
                dataSection
                notificationsSection
                aboutSection
            }
            .navigationTitle("Settings")
        }
    }

    // MARK: - Sections

    private var appearanceSection: some View {
        Section {
            Picker("Theme", selection: $appTheme) {
                ForEach(AppTheme.allCases) { theme in
                    Text(theme.displayName).tag(theme)
                }
            }
            .pickerStyle(.segmented)

            Toggle("Show Images", isOn: $showImages)
        } header: {
            Text("Appearance")
        } footer: {
            Text("Customize how the app looks")
        }
    }

    private var dataSection: some View {
        Section {
            NavigationLink {
                DataManagementView()
            } label: {
                Label("Manage Data", systemImage: "externaldrive")
            }

            Button(role: .destructive) {
                // TODO: Implement clear cache
            } label: {
                Label("Clear Cache", systemImage: "trash")
            }
        } header: {
            Text("Data")
        }
    }

    private var notificationsSection: some View {
        Section {
            Toggle("Enable Notifications", isOn: $enableNotifications)

            if enableNotifications {
                NavigationLink {
                    NotificationSettingsView()
                } label: {
                    Label("Notification Preferences", systemImage: "bell.badge")
                }
            }
        } header: {
            Text("Notifications")
        } footer: {
            Text("Receive notifications about your items")
        }
    }

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0.0")
                    .foregroundStyle(.secondary)
            }

            Link(destination: URL(string: "https://github.com")!) {
                Label("GitHub Repository", systemImage: "link")
            }

            NavigationLink {
                PrivacyPolicyView()
            } label: {
                Label("Privacy Policy", systemImage: "hand.raised")
            }
        } header: {
            Text("About")
        }
    }
}

// MARK: - App Theme

enum AppTheme: String, CaseIterable, Identifiable {
    case light
    case dark
    case system

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }
}

// MARK: - Supporting Views

struct DataManagementView: View {
    var body: some View {
        List {
            Section {
                Button {
                    // TODO: Implement export
                } label: {
                    Label("Export Data", systemImage: "square.and.arrow.up")
                }

                Button {
                    // TODO: Implement import
                } label: {
                    Label("Import Data", systemImage: "square.and.arrow.down")
                }
            }

            Section {
                Button(role: .destructive) {
                    // TODO: Implement delete all
                } label: {
                    Label("Delete All Data", systemImage: "trash")
                }
            } footer: {
                Text("This action cannot be undone")
            }
        }
        .navigationTitle("Manage Data")
    }
}

struct NotificationSettingsView: View {
    @AppStorage("notifyNewItems") private var notifyNewItems = true
    @AppStorage("notifyLowStock") private var notifyLowStock = false

    var body: some View {
        Form {
            Section {
                Toggle("New Items", isOn: $notifyNewItems)
                Toggle("Low Stock Alerts", isOn: $notifyLowStock)
            } header: {
                Text("Notification Types")
            }
        }
        .navigationTitle("Notifications")
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Privacy Policy")
                    .font(.title)
                    .bold()

                Text("Last updated: January 11, 2026")
                    .foregroundStyle(.secondary)

                Text("""
                Your privacy is important to us. This app stores all data locally on your device.

                We do not collect, transmit, or share any personal information.

                All images and data you add to the app remain on your device and are never uploaded to external servers.
                """)
                .font(.body)
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
