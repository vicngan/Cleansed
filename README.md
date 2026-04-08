# Cleansed

Cleansed is an iOS productivity app built with SwiftUI + SwiftData.

It combines:
- Todo management
- Habit tracking with completion history
- Focus groups using Screen Time APIs (FamilyControls + DeviceActivity)
- A Home Screen widget with interactive todo toggles

## Tech Stack

- Swift 5
- SwiftUI
- SwiftData
- WidgetKit + App Intents
- FamilyControls + DeviceActivity (with monitor/report/shield extensions)

## Targets

- `Cleansed/` - Main app
- `TodoWidget/` - Widget extension
- `DeviceActivityMonitorExtension/` - Focus session lifecycle monitor
- `DeviceActivityReportExtension/` - Device activity report scene
- `ShieldActionExtension/` - Shield action hooks
- `ShieldConfigurationExtension/` - Shield UI configuration
- `CleansedTests/` - Unit tests
- `CleansedUITests/` - UI tests

## Core Features

- Todos
  - Create, complete/uncomplete, and delete tasks
  - Shared with widget through App Group storage
- Habits
  - Track completions with history/stat-style views
- Focus
  - Create focus groups to block selected apps/categories
  - Start/stop sessions and display device activity reporting
- Account/Settings
  - Theme toggle
  - Widget appearance customization (size-specific settings)
- Widget
  - Supports interactive todo completion via `ToggleTodoIntent`
  - Supports small/medium/large/extralarge families

## Shared Data and App Groups

The app and extensions use shared `UserDefaults` in App Groups for cross-target data exchange.

Configured app groups in entitlements:
- `group.com.cleansed.shared`
- `group.learn.Cleansed`

`TodoManager` and widget settings use `group.com.cleansed.shared` for todo payload + widget appearance state.

## Requirements

- macOS with Xcode installed
- iOS SDK compatible with the deployment settings in `Cleansed.xcodeproj`
- Apple Developer provisioning/capabilities for:
  - App Groups
  - Family Controls / Device Activity / Managed Settings (for focus blocking features)

## Setup

1. Open `Cleansed.xcodeproj` in Xcode.
2. Select a signing team for all app + extension targets.
3. Verify Signing & Capabilities for each relevant target:
   - App Groups (matching IDs across app/extensions)
   - Family Controls related entitlements
4. Build and run the `Cleansed` scheme on a supported iOS simulator/device.

## Running Tests

From Xcode:
- `Product` -> `Test`

From command line:

```bash
xcodebuild test \
  -project Cleansed.xcodeproj \
  -scheme Cleansed \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Development Notes

### Re-enabling habit calendar editing (test mode)

To allow tapping any day in the habit detail calendar to toggle completions (useful for seeding test data):

1. **`Cleansed/Views/HabitDetailView.swift`** — add back the flag and function:
   ```swift
   // TEST MODE: Set to true to enable calendar editing for testing
   private let enableCalendarEditing = true
   ```
   Add the `toggleCompletion(for:)` function (accepts any `Date`, inserts/removes a `HabitCompletion` in SwiftData + Supabase), then wire the calendar cells:
   ```swift
   onTap: enableCalendarEditing ? { toggleCompletion(for: day.date) } : nil
   ```

2. **`Cleansed/Views/HabitRowView.swift`** — to also allow tapping past days in the 7-day row, change:
   ```swift
   .disabled(state != .today)   // production
   // to:
   .disabled(state == .future)  // test mode (allows past-day toggles)
   ```

## Key Files

- `Cleansed/CleansedApp.swift` - app entry + SwiftData container
- `Cleansed/Views/MainTabView.swift` - tab navigation + widget deep-link handling
- `Cleansed/Managers/TodoManager.swift` - shared todo encoding/sync + widget reloads
- `Cleansed/Intents/ToggleTodoIntent.swift` - widget interaction intent
- `Cleansed/ViewModels/FocusManager.swift` - focus group scheduling/blocking orchestration
- `Cleansed/Views/FocusView.swift` - focus UI + DeviceActivity report embedding
- `TodoWidget/TodoWidget.swift` - widget provider + timeline/config
