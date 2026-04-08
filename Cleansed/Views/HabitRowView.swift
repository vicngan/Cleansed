//
//  HabitRowView.swift
//  Cleansed
//
//  Created by Nguyen Trong Dat on 2/14/26.
//

import SwiftData
import SwiftUI

struct HabitRowView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var auth: AuthManager
    let habit: Habit

    private var last7Days: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: today)
        }.reversed()
    }

    private func isDateCompleted(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: date)
        return habit.completions.contains { completion in
            calendar.startOfDay(for: completion.date) == targetDay
        }
    }

    private func toggleCompletion(for date: Date) {
        let calendar = Calendar.current
        let targetDay = calendar.startOfDay(for: date)

        // Check if already completed
        if let existingCompletion = habit.completions.first(where: { completion in
            calendar.startOfDay(for: completion.date) == targetDay
        }) {
            // Remove completion
            modelContext.delete(existingCompletion)
            HabitWidgetManager.shared.toggleHabitCompletion(id: habit.id, date: targetDay)
            if auth.isAuthenticated {
                Task {
                    try? await SupabaseManager.shared.removeCompletion(
                        habitId: habit.id, date: targetDay)
                }
            }
        } else {
            // Add completion
            let newCompletion = HabitCompletion(date: targetDay, habit: habit)
            modelContext.insert(newCompletion)
            habit.completions.append(newCompletion)
            HabitWidgetManager.shared.toggleHabitCompletion(id: habit.id, date: targetDay)
            if auth.isAuthenticated, let userId = auth.currentUserId {
                Task {
                    try? await SupabaseManager.shared.logCompletionWithId(
                        id: newCompletion.id,
                        habitId: habit.id,
                        userId: userId,
                        date: targetDay
                    )
                }
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top Row: Name and Streak
            HStack {
                Text(habit.name)
                    .font(.title2)
                    .fontWeight(.medium)

                Spacer()

                if habit.calculateStreak() > 0 {
                    HStack(spacing: 4) {
                        Text("\(habit.calculateStreak()) day streak")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Image(systemName: "flame.fill")
                            .foregroundStyle(.orange)
                            .font(.subheadline)
                    }
                }
            }

            // Bottom Row: Week Days
            HStack(spacing: 0) {
                let days = last7Days
                ForEach(0..<days.count, id: \.self) { index in
                    let date = days[index]
                    DayCircleView(
                        date: date,
                        isCompleted: isDateCompleted(date),
                        state: getDayState(for: date),
                        onTap: {
                            withAnimation(.spring(response: 0.3)) {
                                toggleCompletion(for: date)
                            }
                        }
                    )
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.vertical, 12)
    }

    // Helper to determine day state
    private func getDayState(for date: Date) -> DayState {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return .today
        } else if date > Date() {
            return .future
        } else {
            return .past
        }
    }
}

enum DayState {
    case past, today, future
}

struct DayCircleView: View {
    let date: Date
    let isCompleted: Bool
    let state: DayState
    let onTap: () -> Void

    private var dayLabel: String {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        return "\(day)"
    }

    var body: some View {
        Button(action: onTap) {
            ZStack {
                if isCompleted {
                    Circle()
                        .fill(Color.primary)
                } else if state == .today {
                    Circle()
                        .stroke(Color.primary.opacity(0.3), lineWidth: 1)
                } else {
                    Circle()
                        .fill(Color.clear)
                }

                Text(dayLabel)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isCompleted ? Color(.systemBackground) : Color.primary)
            }
            .frame(width: 44, height: 44)
        }
        .buttonStyle(.borderless)
        .disabled(state != .today)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Habit.self, HabitCompletion.self, configurations: config)

    let habit = Habit(name: "Read")
    container.mainContext.insert(habit)

    return List {
        HabitRowView(habit: habit)
    }
    .modelContainer(container)
}
