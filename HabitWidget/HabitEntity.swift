//
//  HabitEntity.swift
//  HabitWidget
//

import AppIntents
import Foundation

@available(iOS 17.0, *)
struct HabitEntity: AppEntity {
    let id: String
    let name: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Habit"
    static var defaultQuery = HabitEntityQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

@available(iOS 17.0, *)
struct HabitEntityQuery: EntityQuery {
    func entities(for identifiers: [HabitEntity.ID]) async throws -> [HabitEntity] {
        let habits = HabitWidgetManager.shared.getHabitsFromUserDefaults()
        return identifiers.compactMap { id in
            if let habit = habits.first(where: { $0.id.uuidString == id }) {
                return HabitEntity(id: habit.id.uuidString, name: habit.name)
            }
            return nil
        }
    }

    func suggestedEntities() async throws -> [HabitEntity] {
        let habits = HabitWidgetManager.shared.getHabitsFromUserDefaults()
        return habits.map { HabitEntity(id: $0.id.uuidString, name: $0.name) }
    }

    func defaultResult() async -> HabitEntity? {
        let habits = HabitWidgetManager.shared.getHabitsFromUserDefaults()
        if let first = habits.first {
            return HabitEntity(id: first.id.uuidString, name: first.name)
        }
        return nil
    }
}
