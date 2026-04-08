//
//  FocusView.swift
//  Cleansed
//
//  Created by Nguyen Trong Dat on 2/14/26.
//

import SwiftData
import SwiftUI

struct FocusView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FocusGroup.createdAt, order: .reverse) private var focusGroups: [FocusGroup]

    @State private var screenTimeManager = ScreenTimeManager()
    @State private var showCreateSheet = false
    @State private var currentTime = Date()

    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                // Background color for ZStack consistency
                Color(.systemBackground).ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    List {
                        // MARK: - Authorization Banner
                        if !screenTimeManager.isAuthorized {
                            Section {
                                authorizationBanner
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(
                                        EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
                                    )
                                    .listRowBackground(Color.clear)
                            }
                        }

                        // MARK: - Focus Groups
                        if screenTimeManager.isAuthorized {
                            if focusGroups.isEmpty {
                                Section {
                                    emptyState
                                        .listRowSeparator(.hidden)
                                        .listRowInsets(
                                            EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
                                        )
                                        .listRowBackground(Color.clear)
                                }
                            } else {
                                Section {
                                    Text("Focus Groups")
                                        .font(.headline)
                                        .listRowSeparator(.hidden)
                                        .listRowInsets(
                                            EdgeInsets(
                                                top: 12, leading: 24, bottom: 4, trailing: 24)
                                        )
                                        .listRowBackground(Color.clear)

                                    ForEach(focusGroups) { group in
                                        ZStack {
                                            FocusGroupRow(
                                                group: group,
                                                screenTimeManager: screenTimeManager,
                                                currentTime: currentTime
                                            )
                                            .contentShape(Rectangle())

                                            NavigationLink(
                                                destination: FocusGroupDetailView(
                                                    group: group,
                                                    screenTimeManager: screenTimeManager)
                                            ) {
                                                Color.clear
                                            }
                                            .opacity(0)  // Hide the chevron
                                        }
                                        .listRowSeparator(.hidden)
                                        .listRowInsets(
                                            EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20)
                                        )
                                        .listRowBackground(
                                            Color.clear
                                        )
                                        .deleteDisabled(group.isHardBlockActive)
                                    }
                                    .onDelete(perform: deleteGroupsList)
                                }
                            }

                        }
                    }
                    .listStyle(.plain)
                    .hideListSeparators()  // Use extension to match HabitView
                    .background(Color(.systemBackground))
                }

                // MARK: - FAB
                if screenTimeManager.isAuthorized {
                    FAB {
                        showCreateSheet = true
                    }
                    .padding(24)
                }
            }
            .onAppear {
                screenTimeManager.checkAuthorization()
                checkExpiredTimerGroups()
            }
            .onReceive(timer) { _ in
                currentTime = Date()
                checkExpiredTimerGroups()
            }
            .sheet(isPresented: $showCreateSheet) {
                CreateFocusGroupView(screenTimeManager: screenTimeManager)
            }
        }
    }

    // MARK: - Authorization Banner

    private var authorizationBanner: some View {
        VStack(spacing: 12) {
            Image(systemName: "hourglass.badge.plus")
                .font(.system(size: 40))
                .foregroundStyle(Color.primary)

            Text("Screen Time Access Required")
                .font(.headline)

            Text(
                "Grant Screen Time access to create focus sessions that block distracting apps."
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)

            Button {
                Task {
                    await screenTimeManager.requestAuthorization()
                }
            } label: {
                Text("Grant Access")
                    .font(.headline)
                    .foregroundStyle(Color(.systemBackground))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.top, 4)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "moon.stars")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)

            Text("No Focus Groups")
                .font(.headline)

            Text("Create a focus group to start blocking distracting apps.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Actions

    /// Reset any timer-based groups whose end date has already passed.
    private func checkExpiredTimerGroups() {
        var changed = false
        for group in focusGroups {
            guard group.isEnabled,
                  group.scheduleType == .timer,
                  let endDate = group.timerEndDate,
                  endDate < Date()
            else { continue }
            group.isEnabled = false
            group.timerEndDate = nil
            changed = true
        }
        if changed { try? modelContext.save() }
    }

    private func deleteGroupsList(at offsets: IndexSet) {
        for index in offsets {
            let group = focusGroups[index]
            if group.isHardBlockActive { continue }
            screenTimeManager.removeGroup(group)
            modelContext.delete(group)
        }
        try? modelContext.save()
    }
}

// MARK: - Focus Group Row

struct FocusGroupRow: View {
    @Bindable var group: FocusGroup
    let screenTimeManager: ScreenTimeManager
    let currentTime: Date

    var body: some View {
        HStack(spacing: 14) {
            // Icon
            Image(systemName: group.icon)
                .font(.title3)
                .foregroundStyle(group.color)
                .frame(width: 40, height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(group.color.opacity(0.15))
                )

            // Info
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Text(group.name)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.primary)

                    if group.isHardBlock {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }

                Text(group.scheduleDescription(at: currentTime))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Toggle
            Toggle(
                "",
                isOn: Binding(
                    get: { group.isEnabled },
                    set: { newValue in
                        screenTimeManager.toggleGroup(group, enabled: newValue)
                    }
                )
            )
            .labelsHidden()
            .tint(.green)
            .disabled(group.isHardBlockActive)
        }
        .padding(14)
    }
}

#Preview {
    FocusView()
        .modelContainer(for: FocusGroup.self, inMemory: true)
}
