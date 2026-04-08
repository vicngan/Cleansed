//
//  SupabaseModels.swift
//  Cleansed
//

import Foundation

// MARK: - Profiles

struct UserProfile: Codable, Identifiable {
    let id: UUID
    let email: String?
    var displayName: String?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, email
        case displayName = "display_name"
        case createdAt = "created_at"
    }
}

// MARK: - Habits

struct HabitRecord: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var name: String
    let startDate: String  // "YYYY-MM-DD"
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name
        case userId = "user_id"
        case startDate = "start_date"
        case createdAt = "created_at"
    }
}

// MARK: - Habit Completions

struct HabitCompletionRecord: Codable, Identifiable {
    let id: UUID
    let habitId: UUID
    let userId: UUID
    let completedDate: String  // "YYYY-MM-DD"
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case habitId = "habit_id"
        case userId = "user_id"
        case completedDate = "completed_date"
        case createdAt = "created_at"
    }
}

// MARK: - Todo Items

struct TodoRecord: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var title: String
    var isCompleted: Bool
    var completedAt: Date?
    var sortDate: Date?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, title
        case userId = "user_id"
        case isCompleted = "is_completed"
        case completedAt = "completed_at"
        case sortDate = "sort_date"
        case createdAt = "created_at"
    }
}
