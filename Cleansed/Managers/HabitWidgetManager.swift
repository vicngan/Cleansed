//
//  HabitWidgetManager.swift
//  Cleansed
//

import Foundation
import SwiftData
import WidgetKit

/// Simplified habit data structure for widget
struct HabitWidgetData: Codable {
    let id: UUID
    let name: String
    let completedDates: [Date]
    let colorTheme: String
    let iconName: String

    init(id: UUID, name: String, completedDates: [Date], colorTheme: String, iconName: String = "flame.fill") {
        self.id = id
        self.name = name
        self.completedDates = completedDates
        self.colorTheme = colorTheme
        self.iconName = iconName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        completedDates = try container.decode([Date].self, forKey: .completedDates)
        colorTheme = try container.decode(String.self, forKey: .colorTheme)
        iconName = try container.decodeIfPresent(String.self, forKey: .iconName) ?? "flame.fill"
    }
}

class HabitWidgetManager {
    static let shared = HabitWidgetManager()

    private let sharedDefaults: UserDefaults
    private let habitsKey = "habitsWidgetData"

    private let colors = ["#A154F2", "#F2C035", "#35F28A", "#F26D85", "#5C99F2"]
    // Must cover the largest widget grid: 8 rows × 26 cols = up to 206 days back.
    private let maxHabitHistoryDays = 210

    private init() {
        sharedDefaults = UserDefaults(suiteName: "group.com.cleansed.shared")!
    }

    private func getColor(for id: UUID) -> String {
        // Hash the UUID to deterministically pick a color
        let absHash = abs(id.hashValue)
        return colors[absHash % colors.count]
    }

    func syncHabitsToUserDefaults(_ habits: [Habit]) {
        let calendar = Calendar.current
        let cutoff = calendar.date(byAdding: .day, value: -maxHabitHistoryDays, to: Date()) ?? Date()

        let habitData = habits.map { habit in
            let validDates = habit.completions.map { $0.date }.filter { $0 >= cutoff }
            let colorTheme = habit.colorHex.isEmpty ? getColor(for: habit.id) : habit.colorHex
            let iconName = habit.iconName.isEmpty ? "flame.fill" : habit.iconName
            return HabitWidgetData(
                id: habit.id,
                name: habit.name,
                completedDates: validDates,
                colorTheme: colorTheme,
                iconName: iconName
            )
        }

        let sortedHabitData = habitData.sorted(by: { $0.name < $1.name })

        if let encoded = try? JSONEncoder().encode(sortedHabitData) {
            sharedDefaults.set(encoded, forKey: habitsKey)
            reloadWidgets()
        }
    }

    func getHabitsFromUserDefaults() -> [HabitWidgetData] {
        guard let data = sharedDefaults.data(forKey: habitsKey),
            let habits = try? JSONDecoder().decode([HabitWidgetData].self, from: data)
        else {
            return []
        }
        return habits
    }

    func toggleHabitCompletion(id: UUID, date: Date) {
        var habits = getHabitsFromUserDefaults()
        guard let index = habits.firstIndex(where: { $0.id == id }) else { return }

        let calendar = Calendar.current
        var dates = habits[index].completedDates

        if let existingIndex = dates.firstIndex(where: { calendar.isDate($0, inSameDayAs: date) }) {
            dates.remove(at: existingIndex)  // Uncomplete
        } else {
            dates.append(date)  // Complete
        }

        habits[index] = HabitWidgetData(
            id: habits[index].id,
            name: habits[index].name,
            completedDates: dates,
            colorTheme: habits[index].colorTheme,
            iconName: habits[index].iconName
        )

        if let encoded = try? JSONEncoder().encode(habits) {
            sharedDefaults.set(encoded, forKey: habitsKey)
            reloadWidgets()
        }
    }

    func updateHabitAppearance(id: UUID, colorHex: String, iconName: String) {
        var habits = getHabitsFromUserDefaults()
        guard let index = habits.firstIndex(where: { $0.id == id }) else { return }
        habits[index] = HabitWidgetData(
            id: habits[index].id,
            name: habits[index].name,
            completedDates: habits[index].completedDates,
            colorTheme: colorHex,
            iconName: iconName
        )
        if let encoded = try? JSONEncoder().encode(habits) {
            sharedDefaults.set(encoded, forKey: habitsKey)
            reloadWidgets()
        }
    }

    func reloadWidgets() {
        WidgetCenter.shared.reloadTimelines(ofKind: "HabitWidget")
    }
}
