//
//  TodoManager.swift
//  Cleansed
//
//  Created by Nguyen Trong Dat on 2/17/26.
//

import Foundation
import SwiftData
import WidgetKit

/// Shared sort ordering for todos: incomplete first (oldest sortDate → newest),
/// then completed (most recently completed → oldest).
protocol TodoSortable {
    var isCompleted: Bool { get }
    var completedAt: Date? { get }
    var createdAt: Date { get }
    var sortDate: Date { get }
}

extension Array where Element: TodoSortable {
    func sortedByCompletion() -> [Element] {
        sorted {
            if $0.isCompleted != $1.isCompleted { return !$0.isCompleted }
            if $0.isCompleted {
                return ($0.completedAt ?? $0.createdAt) > ($1.completedAt ?? $1.createdAt)
            } else {
                return $0.sortDate < $1.sortDate
            }
        }
    }
}

/// Simplified todo data structure for widget communication
struct TodoItemData: Codable, TodoSortable {
    let id: UUID
    let title: String
    let isCompleted: Bool
    let createdAt: Date
    let completedAt: Date?
    let sortDate: Date
}

/// Manages synchronization between SwiftData and UserDefaults for widget access
class TodoManager {
    static let shared = TodoManager()

    private let sharedDefaults: UserDefaults
    private let todosKey = "todos"

    private init() {
        sharedDefaults = UserDefaults(suiteName: "group.com.cleansed.shared")!
    }

    /// Sync todos from SwiftData to UserDefaults for widget access
    func syncTodosToUserDefaults(_ todos: [TodoItem]) {
        let todoData = sorted(
            todos.map { todo in
                TodoItemData(
                    id: todo.id,
                    title: todo.title,
                    isCompleted: todo.isCompleted,
                    createdAt: todo.createdAt,
                    completedAt: todo.completedAt,
                    sortDate: todo.sortDate
                )
            })

        if let encoded = try? JSONEncoder().encode(todoData) {
            sharedDefaults.set(encoded, forKey: todosKey)
            reloadWidgets()
        }
    }

    /// Get todos from UserDefaults (used by widget)
    func getTodosFromUserDefaults() -> [TodoItemData] {
        guard let data = sharedDefaults.data(forKey: todosKey),
            let todos = try? JSONDecoder().decode([TodoItemData].self, from: data)
        else {
            return []
        }
        return todos
    }

    /// Toggle todo completion status (called from widget intent)
    func toggleTodo(id: UUID) {
        var todos = getTodosFromUserDefaults()

        if let index = todos.firstIndex(where: { $0.id == id }) {
            let todo = todos[index]
            let nowCompleted = !todo.isCompleted

            // If checking (incomplete -> complete): set completedAt = Now
            // If unchecking (complete -> incomplete): set sortDate = Now (moves to bottom of list)
            let newCompletedAt = nowCompleted ? Date() : nil
            let newSortDate = nowCompleted ? todo.sortDate : Date()

            todos[index] = TodoItemData(
                id: todo.id,
                title: todo.title,
                isCompleted: nowCompleted,
                createdAt: todo.createdAt,
                completedAt: newCompletedAt,
                sortDate: newSortDate
            )

            if let encoded = try? JSONEncoder().encode(sorted(todos)) {
                sharedDefaults.set(encoded, forKey: todosKey)
                reloadWidgets()
            }
        }
    }

    private func sorted(_ todos: [TodoItemData]) -> [TodoItemData] {
        todos.sortedByCompletion()
    }

    /// Trigger widget timeline reload
    func reloadWidgets() {
        WidgetCenter.shared.reloadTimelines(ofKind: "TodoWidget")
    }
}
