//
//  DataSyncManager.swift
//  Cleansed
//

import Foundation
import OSLog
import SwiftData

private let logger = Logger(subsystem: "com.cleansed", category: "DataSync")

/// Coordinates syncing todos and habits between Supabase (cloud) and SwiftData (local mirror).
@MainActor
class DataSyncManager: ObservableObject {
    static let shared = DataSyncManager()
    private init() {}

    // All in-memory — reset each launch so cold-start always picks up remote changes.
    private var lastSyncedUserId: UUID?
    private var lastSyncedAt: Date?
    private var isCurrentlySyncing = false

    // MARK: - Load from Supabase into SwiftData (called on sign-in / cold start)

    /// Full sync. Guarded against double-calls within the same session startup
    /// (both HabitView and TodoView fire .task on the same launch).
    func loadFromSupabase(userId: UUID, context: ModelContext) async {
        guard lastSyncedUserId != userId else { return }
        await loadTodos(userId: userId, context: context)
        await loadHabits(userId: userId, context: context)
        lastSyncedUserId = userId
        lastSyncedAt = Date()
    }

    /// Syncs only if the last sync was more than `staleAfter` seconds ago.
    /// Called when the app returns to the foreground so long-running sessions
    /// pick up changes made on other devices.
    func syncIfStale(
        userId: UUID, context: ModelContext, staleAfter: TimeInterval = 600
    ) async {
        guard !isCurrentlySyncing else { return }
        if let lastDate = lastSyncedAt,
            lastSyncedUserId == userId,
            Date().timeIntervalSince(lastDate) < staleAfter
        {
            return
        }
        isCurrentlySyncing = true
        defer { isCurrentlySyncing = false }
        lastSyncedUserId = nil  // bypass the startup guard so loadFromSupabase proceeds
        await loadFromSupabase(userId: userId, context: context)
    }

    // MARK: - Migrate guest data to Supabase (called when guest signs up / logs in)

    func migrateGuestData(
        userId: UUID,
        localTodos: [TodoItem],
        localHabits: [Habit],
        context: ModelContext
    ) async {
        await migrateTodos(userId: userId, localTodos: localTodos)
        await migrateHabits(userId: userId, localHabits: localHabits)
        // After migration, reload from Supabase to sync IDs (force re-sync)
        lastSyncedUserId = nil
        await loadFromSupabase(userId: userId, context: context)
    }

    // MARK: - Clear local data on sign-out

    func clearLocalData(context: ModelContext) {
        lastSyncedUserId = nil
        lastSyncedAt = nil
        // IMPORTANT: context.delete(model:) is a batch delete that bypasses
        // SwiftData cascade rules, causing constraint violations when
        // HabitCompletion has a mandatory relationship back to Habit.
        // Always fetch-and-delete individually, completions first.
        do {
            let completions = try context.fetch(FetchDescriptor<HabitCompletion>())
            for c in completions { context.delete(c) }

            let habits = try context.fetch(FetchDescriptor<Habit>())
            for h in habits { context.delete(h) }

            let todos = try context.fetch(FetchDescriptor<TodoItem>())
            for t in todos { context.delete(t) }

            try context.save()
        } catch {
            logger.error("Failed to clear local data: \(error)")
        }
    }

    // MARK: - Private: Todos

    private func loadTodos(userId: UUID, context: ModelContext) async {
        do {
            let remoteTodos = try await SupabaseManager.shared.fetchTodos(userId: userId)
            let existing = try context.fetch(FetchDescriptor<TodoItem>())
            let localById = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })
            let remoteIds = Set(remoteTodos.map { $0.id })

            for record in remoteTodos {
                if let local = localById[record.id] {
                    // Update mutable fields from remote
                    local.title = record.title
                    local.isCompleted = record.isCompleted
                    local.completedAt = record.completedAt
                    if let sortDate = record.sortDate { local.sortDate = sortDate }
                } else {
                    let item = TodoItem(title: record.title, isCompleted: record.isCompleted)
                    item.id = record.id
                    if let completedAt = record.completedAt { item.completedAt = completedAt }
                    if let sortDate = record.sortDate { item.sortDate = sortDate }
                    if let createdAt = record.createdAt { item.createdAt = createdAt }
                    context.insert(item)
                }
            }

            // Remove local todos deleted on another device
            for local in existing where !remoteIds.contains(local.id) {
                context.delete(local)
            }

            try context.save()
        } catch {
            logger.error("Failed to load todos: \(error)")
        }
    }

    private func migrateTodos(userId: UUID, localTodos: [TodoItem]) async {
        for todo in localTodos {
            do {
                _ = try await SupabaseManager.shared.createTodoWithId(
                    id: todo.id,
                    title: todo.title,
                    isCompleted: todo.isCompleted,
                    completedAt: todo.completedAt,
                    sortDate: todo.sortDate,
                    userId: userId
                )
            } catch {
                logger.error("Failed to migrate todo '\(todo.title)': \(error)")
            }
        }
    }

    // MARK: - Private: Habits

    private func loadHabits(userId: UUID, context: ModelContext) async {
        do {
            // 2 parallel network calls instead of 1 + N (one per habit)
            async let habitsFetch = SupabaseManager.shared.fetchHabits(userId: userId)
            async let completionsFetch = SupabaseManager.shared.fetchAllCompletions(userId: userId)
            let (remoteHabits, allRemoteCompletions) = try await (habitsFetch, completionsFetch)

            // Group all completions by habit ID up front
            let completionsByHabitId = Dictionary(
                grouping: allRemoteCompletions, by: { $0.habitId })

            let existingHabits = try context.fetch(FetchDescriptor<Habit>())
            let localHabitById = Dictionary(uniqueKeysWithValues: existingHabits.map { ($0.id, $0) })
            let remoteHabitIds = Set(remoteHabits.map { $0.id })

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"

            for record in remoteHabits {
                let habit: Habit
                if let existing = localHabitById[record.id] {
                    existing.name = record.name
                    habit = existing
                } else {
                    let startDate = formatter.date(from: record.startDate) ?? Date()
                    let newHabit = Habit(name: record.name, startDate: startDate)
                    newHabit.id = record.id
                    if let createdAt = record.createdAt { newHabit.createdAt = createdAt }
                    context.insert(newHabit)
                    habit = newHabit
                }

                let remoteCompletions = completionsByHabitId[record.id] ?? []
                let localCompletionById = Dictionary(
                    uniqueKeysWithValues: habit.completions.map { ($0.id, $0) })
                let remoteCompletionIds = Set(remoteCompletions.map { $0.id })

                for comp in remoteCompletions where localCompletionById[comp.id] == nil {
                    let completionDate = formatter.date(from: comp.completedDate) ?? Date()
                    let hc = HabitCompletion(date: completionDate, habit: habit)
                    hc.id = comp.id
                    context.insert(hc)
                }

                // Remove completions deleted on another device
                for local in Array(habit.completions) where !remoteCompletionIds.contains(local.id) {
                    context.delete(local)
                }
            }

            // Remove local habits deleted on another device (cascade removes their completions)
            for local in existingHabits where !remoteHabitIds.contains(local.id) {
                context.delete(local)
            }

            try context.save()
        } catch {
            logger.error("Failed to load habits: \(error)")
        }
    }

    private func migrateHabits(userId: UUID, localHabits: [Habit]) async {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        for habit in localHabits {
            do {
                _ = try await SupabaseManager.shared.createHabitWithId(
                    id: habit.id,
                    name: habit.name,
                    userId: userId,
                    startDate: habit.startDate
                )
                for completion in habit.completions {
                    try await SupabaseManager.shared.logCompletionWithId(
                        id: completion.id,
                        habitId: habit.id,
                        userId: userId,
                        date: completion.date
                    )
                }
            } catch {
                logger.error("Failed to migrate habit '\(habit.name)': \(error)")
            }
        }
    }
}
