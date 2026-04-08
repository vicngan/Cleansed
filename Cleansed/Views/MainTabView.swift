//
//  MainTabView.swift
//  Cleansed
//
//  Created by Nguyen Trong Dat on 2/14/26.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @AppStorage("hasSeenTutorial") private var hasSeenTutorial = false
    @State private var showTutorial = false

    var body: some View {
        TabView(selection: $selectedTab) {
            TodoView()
                .tabItem {
                    Label("Todos", systemImage: "list.bullet")
                }
                .tag(0)

            HabitView()
                .tabItem {
                    Label("Habits", systemImage: "square.grid.2x2")
                }
                .tag(1)

            FocusView()
                .tabItem {
                    Label("Focus", systemImage: "hourglass")
                }
                .tag(2)

            AccountView()
                .tabItem {
                    Label("Account", systemImage: "person.circle")
                }
                .tag(3)
        }
        .tint(Color.primary)  // Black in Light, White in Dark
        .onOpenURL { url in
            // Handle deep linking from widget
            if url.scheme == "clero", url.host == "todos" {
                selectedTab = 0
            }
        }
        .onAppear {
            if !hasSeenTutorial {
                showTutorial = true
                hasSeenTutorial = true
            }
        }
        .fullScreenCover(isPresented: $showTutorial) {
            TutorialView()
        }
    }
}

#Preview {
    MainTabView()
}
