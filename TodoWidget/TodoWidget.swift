//
//  TodoWidget.swift
//  TodoWidget
//
//  Created by Nguyen Trong Dat on 2/17/26.
//

import AppIntents
import SwiftUI
import WidgetKit

// MARK: - Timeline Entry
// TodoEntry is defined in WidgetSettings.swift DO NOT REDEFINE HERE

// MARK: - Timeline Provider
struct TodoProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodoEntry {
        TodoEntry(
            date: Date(),
            todos: [
                TodoItemData(
                    id: UUID(), title: "Sample Todo", isCompleted: false, createdAt: Date(),
                    completedAt: nil, sortDate: Date()),
                TodoItemData(
                    id: UUID(), title: "Another Task", isCompleted: false, createdAt: Date(),
                    completedAt: nil, sortDate: Date()),
            ])
    }

    func getSnapshot(in context: Context, completion: @escaping (TodoEntry) -> Void) {
        let todos = TodoManager.shared.getTodosFromUserDefaults()
        let entry = TodoEntry(date: Date(), todos: todos)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodoEntry>) -> Void) {
        let todos = TodoManager.shared.getTodosFromUserDefaults()
        let entry = TodoEntry(date: Date(), todos: todos)

        // Widget will be manually reloaded after actions, so use .never policy
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

// MARK: - Widget Entry View
struct TodoWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: TodoProvider.Entry

    let settings = WidgetSettings.shared

    var body: some View {
        TodoWidgetContentView(family: family, entry: entry)
            .containerBackground(
                settings.useCustomBackground(for: family)
                    ? AnyShapeStyle(settings.backgroundColorValue(for: family))
                    : AnyShapeStyle(.fill.tertiary),
                for: .widget
            )
            .widgetURL(URL(string: "cleansed://todos"))
    }
}

// MARK: - Widget Configuration
struct TodoWidget: Widget {
    let kind: String = "TodoWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodoProvider()) { (entry: TodoEntry) in
            TodoWidgetEntryView(entry: entry)
        }
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
        .configurationDisplayName("Todo List")
        .description("View and complete your todos from the home screen")
        .contentMarginsDisabled()
    }
}

// MARK: - Preview
#Preview(as: .systemSmall) {
    TodoWidget()
} timeline: {
    TodoEntry(
        date: .now,
        todos: [
            TodoItemData(
                id: UUID(), title: "Buy groceries", isCompleted: false, createdAt: Date(),
                completedAt: nil, sortDate: Date()),
            TodoItemData(
                id: UUID(), title: "Call mom", isCompleted: false, createdAt: Date(),
                completedAt: nil, sortDate: Date()),
            TodoItemData(
                id: UUID(), title: "Finish report", isCompleted: true, createdAt: Date(),
                completedAt: Date(), sortDate: Date()),
        ])
    TodoEntry(
        date: .now,
        todos: [
            TodoItemData(
                id: UUID(), title: "Morning workout", isCompleted: true, createdAt: Date(),
                completedAt: Date(), sortDate: Date()),
            TodoItemData(
                id: UUID(), title: "Team meeting", isCompleted: false, createdAt: Date(),
                completedAt: nil, sortDate: Date()),
            TodoItemData(
                id: UUID(), title: "Team meeting 2", isCompleted: true, createdAt: Date(),
                completedAt: nil, sortDate: Date()),
        ])
}
