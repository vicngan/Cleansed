//
//  FocusGroupDetailView.swift
//  Cleansed
//
//  Created by Nguyen Trong Dat on 2/23/26.
//

import FamilyControls
import SwiftUI

struct FocusGroupDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var group: FocusGroup
    let screenTimeManager: ScreenTimeManager

    @State private var activitySelection = FamilyActivitySelection()
    @State private var showAppPicker = false
    @State private var editedName: String = ""
    @State private var editedIcon: String = ""
    @State private var editedColorHex: String = ""
    @State private var editedScheduleType: ScheduleType = .manual
    @State private var editedStartDate = Date()
    @State private var editedEndDate = Date()
    @State private var editedWeekdays: Set<Int> = []
    @State private var editedTimerDuration: Int = 30
    @State private var customTimerDuration: TimeInterval = 45 * 60

    private var accentColor: Color {
        Color(hex: editedColorHex) ?? .purple
    }

    var body: some View {
        NavigationStack {
            Form {
                statusSection
                nameAndAppearanceSection
                appSelectionSection
                scheduleSection
            }
            .navigationTitle(group.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .familyActivityPicker(
                isPresented: $showAppPicker,
                selection: $activitySelection
            )
            .onChange(of: activitySelection) { _, newSelection in
                screenTimeManager.updateSelection(for: group, selection: newSelection)
            }
            .onAppear {
                loadGroupState()
            }
        }
    }

    // MARK: - Sections

    private var statusSection: some View {
        Section {
            HStack {
                Text("Status")
                Spacer()
                HStack(spacing: 8) {
                    Circle()
                        .fill(group.isEnabled ? Color.green : Color.secondary)
                        .frame(width: 10, height: 10)
                    Text(group.isEnabled ? "Active" : "Inactive")
                        .foregroundStyle(group.isEnabled ? .green : .secondary)
                        .fontWeight(.medium)
                }
            }

            Toggle(
                "Enabled",
                isOn: Binding(
                    get: { group.isEnabled },
                    set: { newValue in
                        screenTimeManager.toggleGroup(group, enabled: newValue)
                    }))
            .tint(.green)
            .disabled(group.isHardBlockActive)
        }
    }

    private var nameAndAppearanceSection: some View {
        Section("Name & Appearance") {
            TextField("Name", text: $editedName)
                .onChange(of: editedName) { _, newVal in
                    group.name = newVal
                }
            IconPickerView(selection: $editedIcon, accentColor: accentColor)
                .onChange(of: editedIcon) { _, newVal in
                    group.icon = newVal
                }
            ColorChipPicker(colors: FocusGroupColors.all, selection: $editedColorHex)
                .onChange(of: editedColorHex) { _, newVal in
                    group.colorHex = newVal
                }
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
                    Text("Edit Blocked Apps")
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
            Text("Blocked Apps")
        }
    }

    private var scheduleSection: some View {
        Section("Activation Mode") {
            Picker("Mode", selection: $editedScheduleType) {
                ForEach(ScheduleType.allCases, id: \.self) { type in
                    Label(type.rawValue, systemImage: type.icon)
                        .tag(type)
                }
            }
            .pickerStyle(.segmented)
            .disabled(group.isHardBlockActive)
            .onChange(of: editedScheduleType) { _, newVal in
                group.scheduleType = newVal
            }

            switch editedScheduleType {
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
                    selection: $editedStartDate,
                    displayedComponents: .hourAndMinute
                )
                .onChange(of: editedStartDate) { _, newVal in
                    let comps = Calendar.current.dateComponents([.hour, .minute], from: newVal)
                    group.startHour = comps.hour ?? 22
                    group.startMinute = comps.minute ?? 0
                }

                DatePicker(
                    "End Time",
                    selection: $editedEndDate,
                    displayedComponents: .hourAndMinute
                )
                .onChange(of: editedEndDate) { _, newVal in
                    let comps = Calendar.current.dateComponents([.hour, .minute], from: newVal)
                    group.endHour = comps.hour ?? 7
                    group.endMinute = comps.minute ?? 0
                }

                WeekdayPickerView(selection: $editedWeekdays, accentColor: accentColor)
                    .onChange(of: editedWeekdays) { _, newVal in
                        group.weekdays = Array(newVal).sorted()
                    }

            case .timer:
                CountDownTimerPicker(duration: $customTimerDuration)
                    .frame(height: 160)
                    .onChange(of: customTimerDuration) { _, seconds in
                        editedTimerDuration = max(1, Int(seconds / 60))
                        group.timerDuration = editedTimerDuration
                    }
            }
        }
    }

    // MARK: - Load State

    private func loadGroupState() {
        editedName = group.name
        editedIcon = group.icon
        editedColorHex = group.colorHex
        editedScheduleType = group.scheduleType
        editedWeekdays = Set(group.weekdays)
        editedTimerDuration = group.timerDuration
        customTimerDuration = TimeInterval(group.timerDuration * 60)

        editedStartDate =
            Calendar.current.date(
                from: DateComponents(hour: group.startHour, minute: group.startMinute))
            ?? Date()
        editedEndDate =
            Calendar.current.date(
                from: DateComponents(hour: group.endHour, minute: group.endMinute)) ?? Date()

        // Load app selection
        screenTimeManager.loadSelection(for: group)
        activitySelection = screenTimeManager.activitySelection
    }
}
