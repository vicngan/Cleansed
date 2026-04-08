//
//  ToggleHabitIntent.swift
//  Cleansed
//

import AppIntents
import Foundation

struct ToggleHabitIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Habit"
    static var description = IntentDescription("Toggle the completion status of a habit for today")

    @Parameter(title: "Habit ID")
    var habitId: String

    init(habitId: String) {
        self.habitId = habitId
    }

    init() {
        self.habitId = ""
    }

    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: habitId) else {
            return .result()
        }

        // Optimistically update the widget state for today
        HabitWidgetManager.shared.toggleHabitCompletion(id: uuid, date: Date())

        // Note: For a true full-stack sync, the main app will read this on next launch
        // or SwiftData needs to be synced inside the background if possible,
        // but typically App Groups UserDefaults handle the widget UI immediately.

        return .result()
    }
}
