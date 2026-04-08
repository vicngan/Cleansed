//
//  SupabaseManager.swift
//  Cleansed
//

import Foundation
import Supabase

class SupabaseManager {
    static let shared = SupabaseManager()
    private init() {}

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    // MARK: - Profile

    func fetchProfile(userId: UUID) async throws -> UserProfile {
        return
            try await supabase
            .from("profiles")
            .select()
            .eq("id", value: userId.uuidString)
            .single()
            .execute()
            .value
    }

    func updateProfile(userId: UUID, displayName: String) async throws {
        try await supabase
            .from("profiles")
            .update(["display_name": displayName])
            .eq("id", value: userId.uuidString)
            .execute()
    }

    // MARK: - Habits

    func fetchHabits(userId: UUID) async throws -> [HabitRecord] {
        return
            try await supabase
            .from("habits")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: true)
            .execute()
            .value
    }

    func createHabit(name: String, userId: UUID, startDate: Date = Date()) async throws
        -> HabitRecord
    {
        let dateStr = dateFormatter.string(from: startDate)
        return
            try await supabase
            .from("habits")
            .insert(["user_id": userId.uuidString, "name": name, "start_date": dateStr])
            .select()
            .single()
            .execute()
            .value
    }

    /// Upsert habit preserving a specific UUID (used for guest migration).
    @discardableResult
    func createHabitWithId(id: UUID, name: String, userId: UUID, startDate: Date) async throws
        -> HabitRecord
    {
        let dateStr = dateFormatter.string(from: startDate)
        return
            try await supabase
            .from("habits")
            .upsert([
                "id": id.uuidString, "user_id": userId.uuidString, "name": name,
                "start_date": dateStr,
            ])
            .select()
            .single()
            .execute()
            .value
    }

    func renameHabit(id: UUID, name: String) async throws {
        try await supabase
            .from("habits")
            .update(["name": name])
            .eq("id", value: id.uuidString)
            .execute()
    }

    func deleteHabit(id: UUID) async throws {
        try await supabase
            .from("habits")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Habit Completions

    func fetchCompletions(habitId: UUID) async throws -> [HabitCompletionRecord] {
        return
            try await supabase
            .from("habit_completions")
            .select()
            .eq("habit_id", value: habitId.uuidString)
            .order("completed_date", ascending: false)
            .execute()
            .value
    }

    /// Fetch all completions for a user in one call (avoids N+1 per-habit fetches).
    func fetchAllCompletions(userId: UUID) async throws -> [HabitCompletionRecord] {
        return
            try await supabase
            .from("habit_completions")
            .select()
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
    }

    func logCompletion(habitId: UUID, userId: UUID, date: Date = Date()) async throws {
        let dateStr = dateFormatter.string(from: date)
        try await supabase
            .from("habit_completions")
            .upsert([
                "habit_id": habitId.uuidString, "user_id": userId.uuidString,
                "completed_date": dateStr,
            ])
            .execute()
    }

    /// Upsert completion preserving a specific UUID (used for guest migration).
    func logCompletionWithId(id: UUID, habitId: UUID, userId: UUID, date: Date) async throws {
        let dateStr = dateFormatter.string(from: date)
        try await supabase
            .from("habit_completions")
            .upsert([
                "id": id.uuidString, "habit_id": habitId.uuidString, "user_id": userId.uuidString,
                "completed_date": dateStr,
            ])
            .execute()
    }

    func removeCompletion(habitId: UUID, date: Date) async throws {
        let dateStr = dateFormatter.string(from: date)
        try await supabase
            .from("habit_completions")
            .delete()
            .eq("habit_id", value: habitId.uuidString)
            .eq("completed_date", value: dateStr)
            .execute()
    }

    func deleteCompletion(id: UUID) async throws {
        try await supabase
            .from("habit_completions")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Todo Items

    func fetchTodos(userId: UUID) async throws -> [TodoRecord] {
        return
            try await supabase
            .from("todo_items")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("sort_date", ascending: true)
            .execute()
            .value
    }

    func createTodo(title: String, userId: UUID) async throws -> TodoRecord {
        return
            try await supabase
            .from("todo_items")
            .insert(["user_id": userId.uuidString, "title": title])
            .select()
            .single()
            .execute()
            .value
    }

    /// Upsert todo preserving a specific UUID (used for guest migration).
    @discardableResult
    func createTodoWithId(
        id: UUID, title: String, isCompleted: Bool,
        completedAt: Date?, sortDate: Date, userId: UUID
    ) async throws -> TodoRecord {
        var payload: [String: String] = [
            "id": id.uuidString,
            "user_id": userId.uuidString,
            "title": title,
            "is_completed": isCompleted ? "true" : "false",
            "sort_date": ISO8601DateFormatter().string(from: sortDate),
        ]
        if let completedAt {
            payload["completed_at"] = ISO8601DateFormatter().string(from: completedAt)
        }
        return
            try await supabase
            .from("todo_items")
            .upsert(payload)
            .select()
            .single()
            .execute()
            .value
    }

    func completeTodo(id: UUID, isCompleted: Bool) async throws {
        if isCompleted {
            try await supabase
                .from("todo_items")
                .update([
                    "is_completed": "true",
                    "completed_at": ISO8601DateFormatter().string(from: Date()),
                ])
                .eq("id", value: id.uuidString)
                .execute()
        } else {
            try await supabase
                .from("todo_items")
                .update(["is_completed": "false"])
                .eq("id", value: id.uuidString)
                .execute()
        }
    }

    func renameTodo(id: UUID, title: String) async throws {
        try await supabase
            .from("todo_items")
            .update(["title": title])
            .eq("id", value: id.uuidString)
            .execute()
    }

    func deleteTodo(id: UUID) async throws {
        try await supabase
            .from("todo_items")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}
