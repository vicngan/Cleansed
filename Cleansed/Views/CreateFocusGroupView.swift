//
//  CreateFocusGroupView.swift
//  Cleansed
//
//  Created by Nguyen Trong Dat on 2/23/26.
//

import FamilyControls
import SwiftData
import SwiftUI

struct CreateFocusGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let screenTimeManager: ScreenTimeManager

    // Form state
    @State private var name = ""
    @State private var selectedIcon = "moon.fill"
    @State private var selectedColorHex = "#5E5CE6"
    @State private var isHardBlock = false
    @State private var scheduleType: ScheduleType = .manual
    @State private var startHour = 22
    @State private var startMinute = 0
    @State private var endHour = 7
    @State private var endMinute = 0
    @State private var selectedWeekdays: Set<Int> = Set(1...7)
    @State private var timerDuration = 30
    @State private var customTimerDuration: TimeInterval = 45 * 60

    // App selection
    @State private var activitySelection = FamilyActivitySelection()
    @State private var showAppPicker = false

    // Time picker
    @State private var startDate = Calendar.current.date(
        from: DateComponents(hour: 22, minute: 0))!
    @State private var endDate = Calendar.current.date(
        from: DateComponents(hour: 7, minute: 0))!

    private var accentColor: Color {
        Color(hex: selectedColorHex) ?? .purple
    }

    var body: some View {
        NavigationStack {
            Form {
                nameAndAppearanceSection
                appSelectionSection
                scheduleSection
                saveSection
            }
            .navigationTitle("New Focus")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .familyActivityPicker(
                isPresented: $showAppPicker,
                selection: $activitySelection
            )
        }
    }

    // MARK: - Sections

    private var nameAndAppearanceSection: some View {
        Section("Name & Appearance") {
            TextField("Focus group name", text: $name)
            IconPickerView(selection: $selectedIcon, accentColor: accentColor)
            ColorChipPicker(colors: FocusGroupColors.all, selection: $selectedColorHex)
        }
    }

    private var appSelectionSection: some View {
        Section {
            Button {
                showAppPicker = true
            } label: {
                HStack {
                    Image(systemName: "app.badge")
                        .foregroundStyle(accentColor)
                    Text("Select Apps to Block")
                    Spacer()
                    let count =
                        activitySelection.applicationTokens.count
                        + activitySelection.categoryTokens.count
                    if count > 0 {
                        Text("\(count) selected")
                            .foregroundStyle(.secondary)
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
        } header: {
            Text("Apps to Block")
        } footer: {
            Text(
                "Choose specific apps or entire categories to block when this focus is active."
            )
        }
    }

    private var scheduleSection: some View {
        Section("Activation Mode") {
            Picker("Mode", selection: $scheduleType) {
                ForEach(ScheduleType.allCases, id: \.self) { type in
                    Label(type.rawValue, systemImage: type.icon)
                        .tag(type)
                }
            }
            .pickerStyle(.segmented)

            switch scheduleType {
            case .manual:
                HStack {
                    Image(systemName: "hand.tap")
                        .foregroundStyle(.secondary)
                    Text("Toggle this focus group on or off manually.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

            case .scheduled:
                DatePicker(
                    "Start Time",
                    selection: $startDate,
                    displayedComponents: .hourAndMinute
                )
                .onChange(of: startDate) { _, newVal in
                    let comps = Calendar.current.dateComponents([.hour, .minute], from: newVal)
                    startHour = comps.hour ?? 22
                    startMinute = comps.minute ?? 0
                }

                DatePicker(
                    "End Time",
                    selection: $endDate,
                    displayedComponents: .hourAndMinute
                )
                .onChange(of: endDate) { _, newVal in
                    let comps = Calendar.current.dateComponents([.hour, .minute], from: newVal)
                    endHour = comps.hour ?? 7
                    endMinute = comps.minute ?? 0
                }

                WeekdayPickerView(selection: $selectedWeekdays, accentColor: accentColor)

            case .timer:
                CountDownTimerPicker(duration: $customTimerDuration)
                    .frame(height: 160)
                    .onChange(of: customTimerDuration) { _, seconds in
                        timerDuration = max(1, Int(seconds / 60))
                    }
            }

            if scheduleType != .manual {
                Section {
                    Toggle("Hard Block", isOn: $isHardBlock)
                        .tint(.red)
                } footer: {
                    Text(
                        "If enabled, this focus session cannot be turned off early or deleted while active. Use with caution."
                    )
                }
            }
        }
    }

    private var saveSection: some View {
        Section {
            Button {
                saveGroup()
            } label: {
                let bgColor: Color = name.isEmpty ? .secondary : accentColor
                Text("Create Focus Group")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(bgColor)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(name.isEmpty)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }
    }

    // MARK: - Save

    private func saveGroup() {
        let group = FocusGroup(
            name: name,
            icon: selectedIcon,
            colorHex: selectedColorHex,
            isEnabled: false,
            isHardBlock: isHardBlock,
            scheduleType: scheduleType,
            startHour: startHour,
            startMinute: startMinute,
            endHour: endHour,
            endMinute: endMinute,
            weekdays: Array(selectedWeekdays).sorted(),
            timerDuration: timerDuration,
            selectedAppTokens: ScreenTimeShared.encode(activitySelection)
        )

        // Store selection in shared defaults
        ScreenTimeShared.storeSelection(activitySelection, for: group.id)

        modelContext.insert(group)
        dismiss()
    }
}
