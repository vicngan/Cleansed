//
//  ToggleTodoIntent.swift
//  Cleansed
//
//  Created by Nguyen Trong Dat on 2/17/26.
//

import AppIntents
import Foundation

/// App Intent to toggle todo completion from widget
struct ToggleTodoIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Todo"
    static var description = IntentDescription("Toggle the completion status of a todo item")

    @Parameter(title: "Todo ID")
    var todoId: String

    init(todoId: String) {
        self.todoId = todoId
    }

    init() {
        self.todoId = ""
    }

    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: todoId) else {
            return .result()
        }

        TodoManager.shared.toggleTodo(id: uuid)
        return .result()
    }
}
