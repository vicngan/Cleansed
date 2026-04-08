# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Cleansed** is an iOS app (SwiftUI + SwiftData) that combines a todo list, habit tracker, and screen time/app blocker (using Apple's Screen Time API). It supports Supabase cloud sync and exposes home screen widgets.

## Build & Run

This is an Xcode project. There is no `xcodeproj` file visible at the repo root — open it directly in Xcode. All builds, tests, and runs are done via Xcode or `xcodebuild`.

```bash
# Build from command line (simulator)
xcodebuild -scheme Cleansed -destination 'platform=iOS Simulator,name=iPhone 16' build

# Run tests
xcodebuild test -scheme Cleansed -destination 'platform=iOS Simulator,name=iPhone 16'

# Run a single test class
xcodebuild test -scheme Cleansed -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:CleansedTests/CleansedTests
```

## Architecture

### App Targets

| Target | Purpose |
|--------|---------|
| `Cleansed` | Main app |
| `TodoWidget` | Home screen todo widget (small/medium/large) |
| `HabitWidget` | Home screen habit contribution grid widget |
| `DeviceActivityMonitorExtension` | Fires when a Screen Time schedule starts/ends |
| `DeviceActivityReportExtension` | Renders screen time usage reports |
| `ShieldActionExtension` | Handles taps on shielded/blocked apps |
| `ShieldConfigurationExtension` | Customizes the shield UI for blocked apps |

### App Group

All targets share **`group.com.cleansed.shared`** via `UserDefaults` for cross-process data. The main app's SwiftData store is intentionally **not** in the App Group (avoids Error 512); widgets read data via `UserDefaults` instead.

### Data Flow

1. **Local persistence**: SwiftData (`ModelContainer`) stores `TodoItem`, `Habit`, `HabitCompletion`, `FocusGroup`.
2. **Cloud sync**: `SupabaseManager` handles Supabase CRUD. `DataSyncManager` coordinates loading from Supabase into SwiftData on sign-in and migrating guest data on upgrade.
3. **Widget data**: `TodoManager.shared` and `HabitWidgetManager.shared` serialize data to `UserDefaults(suiteName: "group.com.cleansed.shared")` so widgets can read it without SwiftData access.
4. **Screen Time**: `ScreenTimeManager` (uses `@Observable`) manages `FamilyControls` authorization, `ManagedSettings` app shielding, and `DeviceActivity` schedules. Shared state for extensions lives in `ScreenTimeShared` (App Group UserDefaults).

### Key Managers

- `AuthManager` — Supabase auth, guest mode, deep link handling (`ObservableObject`, injected as `@EnvironmentObject`)
- `DataSyncManager` — Supabase ↔ SwiftData sync (`@MainActor`, singleton)
- `ScreenTimeManager` — Screen Time + app blocking (`@Observable`, created per-view)
- `TodoManager` — SwiftData → UserDefaults sync for todo widget (singleton)
- `HabitWidgetManager` — SwiftData → UserDefaults sync for habit widget (singleton)
- `SupabaseManager` — Raw Supabase API calls (singleton)

### Navigation

`MainTabView` has 4 tabs: **Todos** (0), **Habits** (1), **Focus** (2), **Account** (3). Deep link `cleansed://todos` switches to tab 0; `cleansed://habits` is handled by the habit widget.

### Design System (`DesignSystem.swift`)

- `MinimalistCheckboxStyle` — Toggle style used for todo rows
- `FAB` — Floating action button (black/white, respects dark mode)
- `.hideListSeparators()` — View modifier for plain list appearance
- `Color(hex:)` / `toHex()` — Hex color utilities (defined in `WidgetSettings.swift`; duplicated in `HabitWidget.swift` for the widget target)

### Widget Customization

`WidgetSettings.shared` stores per-size (small/medium/large) settings in the shared App Group `UserDefaults` using `@AppStorage`. Settings include font size, alignment, padding, spacing, and optional custom background color. The shared `TodoWidgetContentView` and `TodoRowView` structs (in `WidgetSettings.swift`) are used by both widget sizes.

### SwiftData Deletion Order

**Critical**: Always delete `HabitCompletion` before `Habit` — batch deletion (`context.delete(model:)`) bypasses cascade rules and causes constraint violations. Use fetch-and-delete individually. See `DataSyncManager.clearLocalData`.

### Screen Time Extensions

Extensions communicate with the main app via the App Group `UserDefaults`. `ScreenTimeShared` provides the shared keys and encode/decode helpers for `FamilyActivitySelection`. The `DeviceActivityMonitorExtension` fires on schedule boundaries to enable/disable blocking.
