import SwiftData
import SwiftUI

struct HabitDetailView: View {
    let habit: Habit
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var selectedMonth: Date = Date()

    // TEST MODE: Set to true to enable calendar editing for testing
    private let enableCalendarEditing = true

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
            VStack(spacing: 32) {
                // Header Stats
                VStack(spacing: 24) {
                    // Current Streak
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Current streak")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Text("\(habit.calculateStreak()) days")
                                .font(.system(size: 42, weight: .medium, design: .default))
                                .foregroundStyle(Color.primary)
                        }

                        Spacer()
                    }

                    // Best Streak
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Best streak")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Text("\(habit.calculateBestStreak()) days")
                                .font(.system(size: 42, weight: .medium, design: .default))
                                .foregroundStyle(Color.primary)
                        }

                        Spacer()
                    }

                    // Completion Rate
                    HStack(alignment: .top) {
                        let completion = habit.completionRate()
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Completion")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                Spacer()

                                Text("\(completion.count) of \(completion.total) days")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Text("\(completion.percent)%")
                                .font(.system(size: 42, weight: .medium, design: .default))
                                .foregroundStyle(Color.primary)
                        }
                    }
                VStack(spacing: 24) {
                    // Current Streak
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Current streak")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Text("\(habit.calculateStreak()) days")
                                .font(.system(size: 42, weight: .medium, design: .default))
                                .foregroundStyle(Color.primary)
                        }

                        Spacer()
                    }

                    // Best Streak
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Best streak")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            Text("\(habit.calculateBestStreak()) days")
                                .font(.system(size: 42, weight: .medium, design: .default))
                                .foregroundStyle(Color.primary)
                        }

                        Spacer()
                    }

                    // Completion Rate
                    HStack(alignment: .top) {
                        let completion = habit.completionRate()
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Completion")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                Spacer()

                                Text("\(completion.count) of \(completion.total) days")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Text("\(completion.percent)%")
                                .font(.system(size: 42, weight: .medium, design: .default))
                                .foregroundStyle(Color.primary)
                        }
                    }
                }
                .padding(.horizontal)

                // Widget Appearance
                widgetAppearanceSection

                // Calendar Grid
                VStack(alignment: .leading, spacing: 20) {
                    // Month navigation
                    HStack {
                        Button(action: previousMonth) {
                            Image(systemName: "chevron.left")
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(selectedMonth.formatted(.dateTime.month(.wide).year()))
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Button(action: nextMonth) {
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)
                VStack(alignment: .leading, spacing: 20) {
                    // Month navigation
                    HStack {
                        Button(action: previousMonth) {
                            Image(systemName: "chevron.left")
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(selectedMonth.formatted(.dateTime.month(.wide).year()))
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Button(action: nextMonth) {
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal)

                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 16
                        columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 16
                    ) {
                        // Day labels with unique IDs
                        ForEach(Array(dayLabels.enumerated()), id: \.offset) { index, day in
                        // Day labels with unique IDs
                        ForEach(Array(dayLabels.enumerated()), id: \.offset) { index, day in
                            Text(day)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        // Calendar Days
                        let daysInMonth = getDaysInMonth(for: selectedMonth)
                        ForEach(daysInMonth) { day in
                            if day.day == 0 {
                                Color.clear
                                    .frame(height: 40)
                            } else {
                                CalendarDayCell(
                                    day: day.day,
                                    isCompleted: isDateCompleted(day.date),
                                    isToday: Calendar.current.isDateInToday(day.date),
                                    onTap: enableCalendarEditing
                                        ? {
                                            toggleCompletion(for: day.date)
                                        } : nil
                                )
                            }
                        // Calendar Days
                        let daysInMonth = getDaysInMonth(for: selectedMonth)
                        ForEach(daysInMonth) { day in
                            if day.day == 0 {
                                Color.clear
                                    .frame(height: 40)
                            } else {
                                CalendarDayCell(
                                    day: day.day,
                                    isCompleted: isDateCompleted(day.date),
                                    isToday: Calendar.current.isDateInToday(day.date),
                                    onTap: enableCalendarEditing
                                        ? {
                                            toggleCompletion(for: day.date)
                                        } : nil
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(habit.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Calendar Logic

    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]

    private func previousMonth() {
        let calendar = Calendar.current
        if let newMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth) {
            selectedMonth = newMonth
        }
    }

    private func nextMonth() {
        let calendar = Calendar.current
        if let newMonth = calendar.date(byAdding: .month, value: 1, to: selectedMonth) {
            selectedMonth = newMonth
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
        } else {
            // Add completion
            let newCompletion = HabitCompletion(date: targetDay, habit: habit)
            modelContext.insert(newCompletion)
            habit.completions.append(newCompletion)
        }

        try? modelContext.save()
    }

    struct CalendarDay: Identifiable {
        let id: UUID = UUID()
        let day: Int
        let date: Date
    }

    func getDaysInMonth(for month: Date) -> [CalendarDay] {
        let calendar = Calendar.current

        guard let range = calendar.range(of: .day, in: .month, for: month),
            let firstDayOfMonth = calendar.date(
                from: calendar.dateComponents([.year, .month], from: month))
        else {
            return []
        }

        // Calculate offset for the first day of the week (assuming Monday start)
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        // Convert to 0 (Mon) - 6 (Sun)
        // 1(Sun) -> 6
        // 2(Mon) -> 0
        let offset = (firstWeekday + 5) % 7

        var days: [CalendarDay] = []

        // Add empty placeholders with unique IDs
        for _ in 0..<offset {
            days.append(CalendarDay(day: 0, date: Date.distantPast))
        }

        // Add actual days
        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth) {
                days.append(CalendarDay(day: day, date: date))
            }
        }

        return days
    }

    func isDateCompleted(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return habit.completions.contains { completion in
            calendar.isDate(completion.date, inSameDayAs: date)
        }
    }
}

struct CalendarDayCell: View {
    let day: Int
    let isCompleted: Bool
    let isToday: Bool
    let onTap: (() -> Void)?
    let isToday: Bool
    let onTap: (() -> Void)?

    var body: some View {
        Button(action: {
            if let onTap = onTap {
                withAnimation(.spring(response: 0.3)) {
                    onTap()
                }
            }
        }) {
            ZStack {
                if isCompleted {
                    Circle()
                        .fill(Color.primary)
                } else if isToday {
                    Circle()
                        .stroke(Color.primary.opacity(0.3), lineWidth: 1)
                } else {
                    Circle()
                        .fill(Color.clear)
                }
        Button(action: {
            if let onTap = onTap {
                withAnimation(.spring(response: 0.3)) {
                    onTap()
                }
            }
        }) {
            ZStack {
                if isCompleted {
                    Circle()
                        .fill(Color.primary)
                } else if isToday {
                    Circle()
                        .stroke(Color.primary.opacity(0.3), lineWidth: 1)
                } else {
                    Circle()
                        .fill(Color.clear)
                }

                Text("\(day)")
                    .foregroundStyle(isCompleted ? Color(.systemBackground) : Color.primary)
                    .font(.system(size: 16, weight: .medium))
            }
            .frame(height: 40)
                Text("\(day)")
                    .foregroundStyle(isCompleted ? Color(.systemBackground) : Color.primary)
                    .font(.system(size: 16, weight: .medium))
            }
            .frame(height: 40)
        }
        .buttonStyle(.plain)
        .disabled(onTap == nil)
        .buttonStyle(.plain)
        .disabled(onTap == nil)
    }
}
