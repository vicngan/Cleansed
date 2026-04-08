//
//  WidgetSettings.swift
//  Cleansed
//
//  Created by Nguyen Trong Dat on 2/17/26.
//

import AppIntents
import SwiftUI
import WidgetKit

#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
#endif

/// Widget customization settings shared between app and widget
class WidgetSettings {
    static let shared = WidgetSettings()

    private let defaults: UserDefaults

    private init() {
        defaults = UserDefaults(suiteName: "group.com.cleansed.shared")!
    }

    // MARK: - Settings Properties (Only for Large Widget)

    // MARK: - Large Widget Settings
    @AppStorage(
        "widget.large.isLowercase", store: UserDefaults(suiteName: "group.com.cleansed.shared"))
    var largeIsLowercase: Bool = true

    @AppStorage(
        "widget.large.fontSize", store: UserDefaults(suiteName: "group.com.cleansed.shared"))
    var largeFontSize: Int = 25

    @AppStorage(
        "widget.large.alignment", store: UserDefaults(suiteName: "group.com.cleansed.shared"))
    var largeAlignment: String = "leading"

    @AppStorage(
        "widget.large.horizontalPadding",
        store: UserDefaults(suiteName: "group.com.cleansed.shared"))
    var largeHorizontalPadding: Int = 13

    @AppStorage(
        "widget.large.verticalPadding", store: UserDefaults(suiteName: "group.com.cleansed.shared"))
    var largeVerticalPadding: Int = 10

    @AppStorage(
        "widget.large.todosSpacing", store: UserDefaults(suiteName: "group.com.cleansed.shared"))
    var largeTodosSpacing: Int = 5

    @AppStorage(
        "widget.large.fontWeight", store: UserDefaults(suiteName: "group.com.cleansed.shared"))
    var largeFontWeight: String = "medium"

    @AppStorage(
        "widget.large.useCustomBackground",
        store: UserDefaults(suiteName: "group.com.cleansed.shared"))
    var largeUseCustomBackground: Bool = false

    @AppStorage(
        "widget.large.backgroundColor", store: UserDefaults(suiteName: "group.com.cleansed.shared"))
    var largeBackgroundColor: String = "#1C1C1E"

    // MARK: - Medium Widget Settings
    @AppStorage(
        "widget.medium.isLowercase", store: UserDefaults(suiteName: "group.com.cleansed.shared"))
    var mediumIsLowercase: Bool = true

    @AppStorage(
        "widget.medium.fontSize", store: UserDefaults(suiteName: "group.com.cleansed.shared"))
    var mediumFontSize: Int = 18

    @AppStorage(
        "widget.medium.alignment", store: UserDefaults(suiteName: "group.com.cleansed.shared"))
    var mediumAlignment: String = "leading"

    @AppStorage(
        "widget.medium.horizontalPadding",
        store: UserDefaults(suiteName: "group.com.cleansed.shared"))
    var mediumHorizontalPadding: Int = 15

    @AppStorage(
        "widget.medium.verticalPadding", store: UserDefaults(suiteName: "group.com.cleansed.shared")
    )
    var mediumVerticalPadding: Int = 15

    @AppStorage(
        "widget.medium.todosSpacing", store: UserDefaults(suiteName: "group.com.cleansed.shared"))
    var mediumTodosSpacing: Int = 5

    @AppStorage(
        "widget.medium.fontWeight", store: UserDefaults(suiteName: "group.com.cleansed.shared"))
    var mediumFontWeight: String = "medium"

    @AppStorage(
        "widget.medium.useCustomBackground",
        store: UserDefaults(suiteName: "group.com.cleansed.shared"))
    var mediumUseCustomBackground: Bool = false

    @AppStorage(
        "widget.medium.backgroundColor", store: UserDefaults(suiteName: "group.com.cleansed.shared")
    )
    var mediumBackgroundColor: String = "#1C1C1E"

    // MARK: - Small Widget Settings
    @AppStorage(
        "widget.small.isLowercase", store: UserDefaults(suiteName: "group.com.cleansed.shared"))
    var smallIsLowercase: Bool = true

    @AppStorage(
        "widget.small.fontSize", store: UserDefaults(suiteName: "group.com.cleansed.shared"))
    var smallFontSize: Int = 19

    @AppStorage(
        "widget.small.alignment", store: UserDefaults(suiteName: "group.com.cleansed.shared"))
    var smallAlignment: String = "leading"

    @AppStorage(
        "widget.small.horizontalPadding",
        store: UserDefaults(suiteName: "group.com.cleansed.shared"))
    var smallHorizontalPadding: Int = 10

    @AppStorage(
        "widget.small.verticalPadding", store: UserDefaults(suiteName: "group.com.cleansed.shared"))
    var smallVerticalPadding: Int = 10

    @AppStorage(
        "widget.small.todosSpacing", store: UserDefaults(suiteName: "group.com.cleansed.shared"))
    var smallTodosSpacing: Int = 4

    @AppStorage(
        "widget.small.fontWeight", store: UserDefaults(suiteName: "group.com.cleansed.shared"))
    var smallFontWeight: String = "medium"

    @AppStorage(
        "widget.small.useCustomBackground",
        store: UserDefaults(suiteName: "group.com.cleansed.shared"))
    var smallUseCustomBackground: Bool = false

    @AppStorage(
        "widget.small.backgroundColor", store: UserDefaults(suiteName: "group.com.cleansed.shared"))
    var smallBackgroundColor: String = "#1C1C1E"

    // MARK: - Computed Properties

    func textAlignment(for family: WidgetFamily) -> HorizontalAlignment {
        let alignString: String
        switch family {
        case .systemSmall: alignString = smallAlignment
        case .systemMedium: alignString = mediumAlignment
        default: alignString = largeAlignment
        }

        switch alignString {
        case "center": return .center
        case "trailing": return .trailing
        default: return .leading
        }
    }

    func backgroundColorValue(for family: WidgetFamily) -> Color {
        let colorString: String
        switch family {
        case .systemSmall: colorString = smallBackgroundColor
        case .systemMedium: colorString = mediumBackgroundColor
        default: colorString = largeBackgroundColor
        }
        return Color(hex: colorString) ?? Color.black
    }

    func isLowercase(for family: WidgetFamily) -> Bool {
        switch family {
        case .systemSmall: return smallIsLowercase
        case .systemMedium: return mediumIsLowercase
        default: return largeIsLowercase
        }
    }

    func fontSize(for family: WidgetFamily) -> Int {
        switch family {
        case .systemSmall: return smallFontSize
        case .systemMedium: return mediumFontSize
        default: return largeFontSize
        }
    }

    func horizontalPadding(for family: WidgetFamily) -> CGFloat {
        switch family {
        case .systemSmall: return CGFloat(smallHorizontalPadding)
        case .systemMedium: return CGFloat(mediumHorizontalPadding)
        default: return CGFloat(largeHorizontalPadding)
        }
    }

    func verticalPadding(for family: WidgetFamily) -> CGFloat {
        switch family {
        case .systemSmall: return CGFloat(smallVerticalPadding)
        case .systemMedium: return CGFloat(mediumVerticalPadding)
        default: return CGFloat(largeVerticalPadding)
        }
    }

    func todosSpacing(for family: WidgetFamily) -> CGFloat {
        switch family {
        case .systemSmall: return CGFloat(smallTodosSpacing)
        case .systemMedium: return CGFloat(mediumTodosSpacing)
        default: return CGFloat(largeTodosSpacing)
        }
    }

    func fontWeight(for family: WidgetFamily) -> Font.Weight {
        let weightString: String
        switch family {
        case .systemSmall: weightString = smallFontWeight
        case .systemMedium: weightString = mediumFontWeight
        default: weightString = largeFontWeight
        }
        switch weightString {
        case "ultraLight": return .ultraLight
        case "thin": return .thin
        case "light": return .light
        case "regular": return .regular
        case "medium": return .medium
        case "semibold": return .semibold
        case "bold": return .bold
        case "heavy": return .heavy
        case "black": return .black
        default: return .medium
        }
    }

    func useCustomBackground(for family: WidgetFamily) -> Bool {
        switch family {
        case .systemSmall: return smallUseCustomBackground
        case .systemMedium: return mediumUseCustomBackground
        default: return largeUseCustomBackground
        }
    }

    // MARK: - Methods

    func resetToDefaults() {
        // Large
        largeIsLowercase = true
        largeFontSize = 25
        largeFontWeight = "medium"
        largeAlignment = "leading"
        largeHorizontalPadding = 13
        largeVerticalPadding = 10
        largeTodosSpacing = 5
        largeUseCustomBackground = false
        largeBackgroundColor = "#1C1C1E"

        // Medium
        mediumIsLowercase = true
        mediumFontSize = 18
        mediumFontWeight = "medium"
        mediumAlignment = "leading"
        mediumHorizontalPadding = 15
        mediumVerticalPadding = 15
        mediumTodosSpacing = 5
        mediumUseCustomBackground = false
        mediumBackgroundColor = "#1C1C1E"

        // Small
        smallIsLowercase = true
        smallFontSize = 19
        smallFontWeight = "medium"
        smallAlignment = "leading"
        smallHorizontalPadding = 10
        smallVerticalPadding = 10
        smallTodosSpacing = 4
        smallUseCustomBackground = false
        smallBackgroundColor = "#1C1C1E"

        WidgetCenter.shared.reloadAllTimelines()
    }
}

// MARK: - Color Extension
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

    func toHex() -> String {
        #if canImport(UIKit)
            guard let components = UIColor(self).cgColor.components else { return "#000000" }
        #elseif canImport(AppKit)
            guard let components = NSColor(self).cgColor.components else { return "#000000" }
        #else
            return "#000000"
        #endif

        let r = Int(components[0] * 255.0)
        let g = Int(components[1] * 255.0)
        let b = Int(components[2] * 255.0)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

// MARK: - SHARED WIDGET COMPONENTS

// TodoEntry
struct TodoEntry: TimelineEntry {
    let date: Date
    var todos: [TodoItemData]
}

// TodoWidgetContentView
struct TodoWidgetContentView: View {
    let family: WidgetFamily
    let entry: TodoEntry
    let settings = WidgetSettings.shared

    var body: some View {
        VStack(alignment: currentAlignment, spacing: currentTodosSpacing) {
            if entry.todos.isEmpty {
                Spacer()
                VStack(spacing: 4) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                    Text("All clear!")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                Spacer()
            } else {
                if family == .systemLarge || family == .systemExtraLarge {
                    Spacer(minLength: 0)
                }
                let displayTodos = Array(entry.todos.prefix(maxTodos))
                ForEach(displayTodos, id: \.id) { todo in
                    TodoRowView(todo: todo, family: family)
                }
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, currentHorizontalPadding)
        .padding(.vertical, currentVerticalPadding)
    }

    // Settings Helpers
    private var currentAlignment: HorizontalAlignment { return settings.textAlignment(for: family) }
    private var currentTodosSpacing: CGFloat { return settings.todosSpacing(for: family) }
    private var currentHorizontalPadding: CGFloat { return settings.horizontalPadding(for: family) }
    private var currentVerticalPadding: CGFloat { return settings.verticalPadding(for: family) }

    private var maxTodos: Int {
        let widgetHeight: CGFloat
        switch family {
        case .systemSmall: widgetHeight = 158
        case .systemMedium: widgetHeight = 158
        case .systemLarge: widgetHeight = 354
        case .systemExtraLarge: widgetHeight = 354
        default: widgetHeight = 158
        }
        let availableHeight = widgetHeight - (2 * currentVerticalPadding)
        let rowHeight = CGFloat(settings.fontSize(for: family)) * 1.2
        if availableHeight <= 0 { return 0 }
        let count = Int((availableHeight + currentTodosSpacing) / (rowHeight + currentTodosSpacing))
        return max(count, 0)
    }
}

// TodoRowView
struct TodoRowView: View {
    let todo: TodoItemData
    let family: WidgetFamily
    let settings = WidgetSettings.shared

    private var displayTitle: String {
        return settings.isLowercase(for: family) ? todo.title.lowercased() : todo.title
    }

    private var currentFontSize: CGFloat {
        return CGFloat(settings.fontSize(for: family))
    }

    var body: some View {
        HStack {
            Button(intent: ToggleTodoIntent(todoId: todo.id.uuidString)) {
                Text(displayTitle)
                    .font(.system(size: currentFontSize, weight: settings.fontWeight(for: family)))
                    .strikethrough(todo.isCompleted)
                    .foregroundColor(todo.isCompleted ? .secondary : .primary)
                    .lineLimit(1)
            }
            .buttonStyle(.plain)
            Spacer(minLength: 0)
        }
    }
}
