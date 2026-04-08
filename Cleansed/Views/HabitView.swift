//
//  HabitView.swift
//  Cleansed
//
//  Created by Nguyen Trong Dat on 2/14/26.
//

import SwiftData
import SwiftUI

struct HabitView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject var auth: AuthManager
    @Query(sort: \Habit.createdAt) private var habits: [Habit]

    @State private var isAddSheetPresented = false
    @State private var newHabitName = ""
    @State private var hasSynced = false
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                VStack(alignment: .leading, spacing: 0) {
                    if habits.isEmpty {
                        ContentUnavailableView(
                            "No Habits",
                            systemImage: "chart.bar",
                            description: Text("Start building new habits today")
                        )
                        .frame(maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(habits) { habit in
                                ZStack {
                                    HabitRowView(habit: habit)
                                        .contentShape(Rectangle())
                                    NavigationLink(destination: HabitDetailView(habit: habit)) {
                                        Color.clear
                                    }
                                    .opacity(0)
                                }
                                .listRowSeparator(.hidden)
                                .listRowInsets(
                                    EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20)
                                )
                                .listRowBackground(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemBackground))
                                )
                            }
                            .onDelete(perform: deleteHabits)
                        }
                        .hideListSeparators()
                    }
                }
                .background(Color(.systemBackground))
                .onChange(of: habits) { _, newHabits in
                    HabitWidgetManager.shared.syncHabitsToUserDefaults(newHabits)
                }
                .onAppear {
                    syncFromWidget()
                    HabitWidgetManager.shared.syncHabitsToUserDefaults(habits)
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active {
                        syncFromWidget()
                        if auth.isAuthenticated, let userId = auth.currentUserId {
                            Task {
                                await DataSyncManager.shared.syncIfStale(
                                    userId: userId, context: modelContext)
                            }
                        }
                    }
                }

                FAB { isAddSheetPresented = true }
                    .padding(24)
            }
            .task {
                guard !hasSynced, auth.isAuthenticated, let userId = auth.currentUserId else {
                    return
                }
                hasSynced = true
                await DataSyncManager.shared.loadFromSupabase(userId: userId, context: modelContext)
            }
            .sheet(isPresented: $isAddSheetPresented) {
                NavigationStack {
                    Form {
                        Section {
                            TextField("Habit Name", text: $newHabitName)
                                .focused($isFocused)
                                .onSubmit { addHabit() }
                        }
                    }
                    .navigationTitle("New Habit")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                isAddSheetPresented = false
                                newHabitName = ""
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Add") { addHabit() }
                                .disabled(
                                    newHabitName.trimmingCharacters(in: .whitespacesAndNewlines)
                                        .isEmpty)
                        }
                    }
                    .onAppear { isFocused = true }
                }
                .presentationDetents([.height(180)])
            }
        }
    }

    // MARK: - Actions

    private func addHabit() {
        let trimmed = newHabitName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let newHabit = Habit(name: trimmed, startDate: Date())
        modelContext.insert(newHabit)
        try? modelContext.save()

        // Mirror to Supabase if signed in
        if auth.isAuthenticated, let userId = auth.currentUserId {
            Task {
                try? await SupabaseManager.shared.createHabitWithId(
                    id: newHabit.id, name: newHabit.name,
                    userId: userId, startDate: newHabit.startDate)
            }
        }

        newHabitName = ""
        isAddSheetPresented = false
    }

    private func deleteHabits(at offsets: IndexSet) {
        for index in offsets {
            let habit = habits[index]
            if auth.isAuthenticated {
                Task { try? await SupabaseManager.shared.deleteHabit(id: habit.id) }
            }
            modelContext.delete(habit)
        }
        try? modelContext.save()
    }

    private func syncFromWidget() {
        let calendar = Calendar.current
        let widgetHabits = HabitWidgetManager.shared.getHabitsFromUserDefaults()
        var changed = false

        for widgetHabit in widgetHabits {
            if let existing = habits.first(where: { $0.id == widgetHabit.id }) {
                let existingDates = Set(
                    existing.completions.map { calendar.startOfDay(for: $0.date) })
                let widgetDates = Set(
                    widgetHabit.completedDates.map { calendar.startOfDay(for: $0) })

                let today = calendar.startOfDay(for: Date())
                let isCompletedInWidget = widgetDates.contains(today)
                let isCompletedInSwiftData = existingDates.contains(today)

                if isCompletedInWidget && !isCompletedInSwiftData {
                    // Added in widget
                    let newCompletion = HabitCompletion(date: Date(), habit: existing)
                    modelContext.insert(newCompletion)
                    changed = true

                    if auth.isAuthenticated, let userId = auth.currentUserId {
                        Task {
                            try? await SupabaseManager.shared.logCompletionWithId(
                                id: newCompletion.id,
                                habitId: existing.id,
                                userId: userId,
                                date: newCompletion.date
                            )
                        }
                    }
                } else if !isCompletedInWidget && isCompletedInSwiftData {
                    // Removed in widget
                    if let completionToRemove = existing.completions.first(where: {
                        calendar.isDate($0.date, inSameDayAs: today)
                    }) {
                        if auth.isAuthenticated {
                            let compId = completionToRemove.id
                            Task { try? await SupabaseManager.shared.deleteCompletion(id: compId) }
                        }
                        modelContext.delete(completionToRemove)
                        changed = true
                    }
                }
            }
        }
        if changed { try? modelContext.save() }
    }
}

#Preview {
    HabitView()
        .modelContainer(for: [Habit.self, HabitCompletion.self], inMemory: true)
        .environmentObject(AuthManager())
}
