//
//  HabitWidget.swift
//  HabitWidget
//

import AppIntents
import SwiftUI
import WidgetKit

@available(iOS 17.0, *)
struct HabitProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> HabitEntry {
        let dummyDates = generateDummyDates()
        return HabitEntry(
            date: Date(),
            habit: HabitWidgetData(
                id: UUID(), name: "Meditation", completedDates: dummyDates,
                colorTheme: "#A154F2", iconName: "flame.fill")
        )
    }

    func snapshot(for configuration: SelectHabitIntent, in context: Context) async -> HabitEntry {
        let habits = HabitWidgetManager.shared.getHabitsFromUserDefaults()

        if let selectedId = configuration.habit?.id,
            let selectedHabit = habits.first(where: { $0.id.uuidString == selectedId })
        {
            return HabitEntry(date: Date(), habit: selectedHabit)
        }

        if let first = habits.first {
            return HabitEntry(date: Date(), habit: first)
        }

        return placeholder(in: context)
    }

    func timeline(for configuration: SelectHabitIntent, in context: Context) async -> Timeline<
        HabitEntry
    > {
        let habits = HabitWidgetManager.shared.getHabitsFromUserDefaults()

        var currentHabit: HabitWidgetData? = nil
        if let selectedId = configuration.habit?.id {
            currentHabit = habits.first(where: { $0.id.uuidString == selectedId })
        }

        let entry = HabitEntry(date: Date(), habit: currentHabit)
        let nextMidnight = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: Date())!)
        return Timeline(entries: [entry], policy: .after(nextMidnight))
    }

    private func generateDummyDates() -> [Date] {
        let calendar = Calendar.current
        let today = Date()
        var dates: [Date] = []
        for i in 0..<30 {
            if Bool.random() {
                if let d = calendar.date(byAdding: .day, value: -i, to: today) {
                    dates.append(d)
                }
            }
        }
        return dates
    }
}

@available(iOS 17.0, *)
struct HabitEntry: TimelineEntry {
    let date: Date
    let habit: HabitWidgetData?
}

@available(iOS 17.0, *)
struct HabitWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: HabitProvider.Entry

    var body: some View {
        HabitWidgetContentView(family: family, entry: entry)
            .containerBackground(Color(.systemBackground), for: .widget)
            .widgetURL(URL(string: "cleansed://habits"))
    }
}

// Widget Configuration
@available(iOS 17.0, *)
struct HabitWidget: Widget {
    let kind: String = "HabitWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind, intent: SelectHabitIntent.self, provider: HabitProvider()
        ) { entry in
            HabitWidgetEntryView(entry: entry)
        }
        .supportedFamilies([.systemSmall, .systemMedium])
        .configurationDisplayName("Habit Tracker")
        .description("Track your habits directly from the home screen.")
        .contentMarginsDisabled()
    }
}

// ContentView
@available(iOS 17.0, *)
struct HabitWidgetContentView: View {
    let family: WidgetFamily
    let entry: HabitEntry

    // TWEAK: Widget Margin / Padding
    var widgetMargin: CGFloat { 14 }

    var body: some View {
        if let habit = entry.habit {
            HabitSingleView(habit: habit, family: family)
                .padding(widgetMargin)
        } else {
            VStack {
                Text("No Habit Selected")
                    .foregroundColor(.secondary)
                    .font(.system(size: 14))
            }
        }
    }
}

struct HabitSingleView: View {
    let habit: HabitWidgetData
    let family: WidgetFamily

    var themeColor: Color {
        Color(hex: habit.colorTheme) ?? .green
    }

    var isCompletedToday: Bool {
        let calendar = Calendar.current
        return habit.completedDates.contains { calendar.isDate($0, inSameDayAs: Date()) }
    }

    // TWEAK: Rows and Columns
    var rows: Int { 8 }
    var cols: Int { family == .systemSmall ? 12 : 26 }  // Adjust to fill perfectly

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header
            HStack(spacing: 8) {
                // Icon matching Mockup
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(themeColor.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: habit.iconName)
                        .font(.system(size: 16))
                        .foregroundColor(themeColor)
                }

                Text(habit.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Spacer()

                // Toggle Button
                Button(intent: ToggleHabitIntent(habitId: habit.id.uuidString)) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isCompletedToday ? Color.clear : Color.primary.opacity(0.1))
                            .frame(width: 32, height: 32)

                        if isCompletedToday {
                            Image(systemName: "checkmark")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(themeColor)
                        }
                    }
                }
                .buttonStyle(.plain)
            }

            // Contribution Grid — fills all remaining space
            HabitContributionGrid(
                completedDates: habit.completedDates,
                themeColor: themeColor,
                rows: rows,
                cols: cols
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct HabitContributionGrid: View {
    let completedDates: [Date]
    let themeColor: Color
    let rows: Int
    let cols: Int

    var boolGrid: [[Bool]] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var grid = Array(repeating: Array(repeating: false, count: cols), count: rows)

        let currentWeekday = calendar.component(.weekday, from: today)  // 1=Sun, 7=Sat
        let totalDays = cols * rows

        let completedSet = Set(completedDates.map { calendar.startOfDay(for: $0) })

        let daysOffsetToTopLeft = (cols - 1) * rows + (currentWeekday - 1)
        var currentDate = calendar.date(byAdding: .day, value: -daysOffsetToTopLeft, to: today)!

        for col in 0..<cols {
            for row in 0..<rows {
                if currentDate > today {
                    grid[row][col] = false
                } else {
                    grid[row][col] = completedSet.contains(currentDate)
                }
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            }
        }

        return grid
    }
    
    // TWEAK: Grid Spacing and Corner Radius
    var gridSpacing: CGFloat { 3 }
    var squareCornerRadius: CGFloat { 2 }

    var body: some View {
        let grid = boolGrid
        GeometryReader { geo in
            let totalHSpacing = CGFloat(cols - 1) * gridSpacing
            let squareSize = (geo.size.width - totalHSpacing) / CGFloat(cols)
            HStack(spacing: gridSpacing) {
                ForEach(0..<cols, id: \.self) { col in
                    VStack(spacing: gridSpacing) {
                        ForEach(0..<rows, id: \.self) { row in
                            let isCompleted = grid[row][col]
                            RoundedRectangle(cornerRadius: squareCornerRadius)
                                .fill(isCompleted ? themeColor : Color.primary.opacity(0.12))
                                .frame(width: squareSize, height: squareSize)
                        }
                    }
                }
            }
        }
    }
}

// Minimal Color Ext for Hex
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a: UInt64
        let r: UInt64
        let g: UInt64
        let b: UInt64
        switch hex.count {
        case 3:  // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
