//
//  SelectHabitIntent.swift
//  HabitWidget
//

import AppIntents
import WidgetKit

@available(iOS 17.0, *)
struct SelectHabitIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select Habit"
    static var description = IntentDescription("Select which habit this widget should display.")

    @Parameter(title: "Habit")
    var habit: HabitEntity?

    init(habit: HabitEntity) {
        self.habit = habit
    }

    init() {}
}
