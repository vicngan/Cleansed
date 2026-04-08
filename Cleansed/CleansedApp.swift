//
//  CleansedApp.swift
//  Cleansed
//
//  Created by Nguyen Trong Dat on 2/14/26.
//

import FamilyControls
import SwiftData
import SwiftUI

@main
struct CleansedApp: App {
    @AppStorage("appTheme") private var appTheme: AppTheme = .system
    @StateObject private var authManager = AuthManager()

    // Explicitly configure SwiftData to use the app's own container,
    // NOT the App Group container (which causes Error 512 when the
    // Library/Application Support directory doesn't exist yet in the group).
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            TodoItem.self,
            Habit.self,
            HabitCompletion.self,
            FocusGroup.self,
        ])
        // Use the default app container (not App Group) — widget reads via UserDefaults instead
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isAuthenticated || authManager.isGuest {
                    MainTabView()
                        .id(authManager.isAuthenticated)
                } else {
                    SignInView()
                }
            }
            .environmentObject(authManager)
            .preferredColorScheme(appTheme.colorScheme)
            .animation(.easeInOut(duration: 0.35), value: appTheme)
            .onOpenURL { url in
                Task { await authManager.handleDeepLink(url) }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
