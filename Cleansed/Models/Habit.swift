//
//  Habit.swift
//  Cleansed
//
//  Created by Nguyen Trong Dat on 2/14/26.
//

import Foundation
import SwiftData

@Model
final class Habit {
    var id: UUID
    var name: String
    var createdAt: Date
    var startDate: Date
    var colorHex: String = ""
    var iconName: String = ""

    @Relationship(deleteRule: .cascade, inverse: \HabitCompletion.habit)
    var completions: [HabitCompletion] = []

    init(name: String, startDate: Date = Date()) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.startDate = startDate
    }

    // Helper to get completions for the last 7 days
    func getLast7DaysCompletions() -> [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let last7Days = (0..<7).compactMap { offset -> Date? in
            calendar.date(byAdding: .day, value: -offset, to: today)
        }

        let completedDates = completions.map { calendar.startOfDay(for: $0.date) }
        return last7Days.filter { completedDates.contains($0) }
    }

    // Calculate current streak
    func calculateStreak() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let completedDates = Set(completions.map { calendar.startOfDay(for: $0.date) })

        var streak = 0
        var currentDate = today

        while completedDates.contains(currentDate) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                break
            }
            currentDate = previousDay
        }

        return streak
    }
    // Calculate best streak
    func calculateBestStreak() -> Int {
        let calendar = Calendar.current
        let completedDates = Set(completions.map { calendar.startOfDay(for: $0.date) }).sorted()

        var bestStreak = 0
        var currentStreak = 0
        var lastDate: Date?

        for date in completedDates {
            if let last = lastDate,
                let nextDay = calendar.date(byAdding: .day, value: 1, to: last)
            {
                if calendar.isDate(date, inSameDayAs: nextDay) {
                    currentStreak += 1
                } else {
                    bestStreak = max(bestStreak, currentStreak)
                    currentStreak = 1
                }
            } else {
                currentStreak = 1
            }
            lastDate = date
        }

        return max(bestStreak, currentStreak)
    }

    // Calculate completion rate
    func completionRate() -> (percent: Int, count: Int, total: Int) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let start = calendar.startOfDay(for: startDate)

        let components = calendar.dateComponents([.day], from: start, to: today)
        let totalDays = max(1, (components.day ?? 0) + 1)  // Include today

        let completedCount = completions.count
        let percent = Int((Double(completedCount) / Double(totalDays)) * 100)

        return (percent, completedCount, totalDays)
    }
}
