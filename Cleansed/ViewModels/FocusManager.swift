//
//  ScreenTimeManager.swift
//  Cleansed
//
//  Created by Nguyen Trong Dat on 2/23/26.
//

import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings
import OSLog
import SwiftUI

private let logger = Logger(subsystem: "com.cleansed", category: "ScreenTime")

/// Manages Screen Time authorization, app blocking, and schedule monitoring.
@Observable
final class ScreenTimeManager {
    // MARK: - Properties

    var authorizationStatus: AuthorizationStatus = .notDetermined
    var isAuthorized: Bool { authorizationStatus == .approved }

    /// The current FamilyActivitySelection being edited (used by the picker)
    var activitySelection = FamilyActivitySelection()

    /// Shared managed settings store for the main app
    private let store = ManagedSettingsStore()

    /// Device activity center for scheduling
    private let activityCenter = DeviceActivityCenter()

    // MARK: - Authorization

    /// Request Screen Time authorization from the user
    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            await MainActor.run {
                self.authorizationStatus = .approved
                UserDefaults.standard.set(true, forKey: "hasGrantedScreenTime")
            }
        } catch {
            logger.error("Screen Time authorization failed: \(error)")
            await MainActor.run {
                self.authorizationStatus = .denied
                UserDefaults.standard.set(false, forKey: "hasGrantedScreenTime")
            }
        }
    }

    /// Check current authorization status
    func checkAuthorization() {
        switch AuthorizationCenter.shared.authorizationStatus {
        case .approved:
            authorizationStatus = .approved
            UserDefaults.standard.set(true, forKey: "hasGrantedScreenTime")
        case .denied:
            authorizationStatus = .denied
            UserDefaults.standard.set(false, forKey: "hasGrantedScreenTime")
        case .notDetermined:
            if UserDefaults.standard.bool(forKey: "hasGrantedScreenTime") {
                // The framework might be returning .notDetermined temporarily
                Task {
                    await requestAuthorization()
                }
            } else {
                authorizationStatus = .notDetermined
            }
        @unknown default:
            authorizationStatus = .notDetermined
        }
    }

    // MARK: - App Blocking

    /// Enable blocking for a focus group
    func enableBlocking(for group: FocusGroup) {
        guard let data = group.selectedAppTokens,
            let selection = ScreenTimeShared.decode(data)
        else {
            return
        }

        // Store selection in shared defaults for extensions to read
        ScreenTimeShared.storeSelection(selection, for: group.id)

        // Apply shield to selected applications
        let applications = selection.applicationTokens
        let categories = selection.categoryTokens

        store.shield.applications = applications.isEmpty ? nil : applications
        store.shield.applicationCategories =
            categories.isEmpty
            ? nil : ShieldSettings.ActivityCategoryPolicy<Application>.specific(categories)
        store.shield.webDomainCategories =
            categories.isEmpty
            ? nil : ShieldSettings.ActivityCategoryPolicy<WebDomain>.specific(categories)

        // Track active groups
        var activeIDs = ScreenTimeShared.getActiveGroupIDs()
        if !activeIDs.contains(group.id) {
            activeIDs.append(group.id)
            ScreenTimeShared.setActiveGroupIDs(activeIDs)
        }
    }

    /// Disable blocking for a focus group
    func disableBlocking(for group: FocusGroup) {
        // Remove from active groups
        var activeIDs = ScreenTimeShared.getActiveGroupIDs()
        activeIDs.removeAll { $0 == group.id }
        ScreenTimeShared.setActiveGroupIDs(activeIDs)

        // Remove stored selection
        ScreenTimeShared.removeSelection(for: group.id)

        // If no active groups remain, clear all shields
        if activeIDs.isEmpty {
            store.shield.applications = nil
            store.shield.applicationCategories = nil
            store.shield.webDomainCategories = nil
        } else {
            // Re-apply shields from remaining active groups
            reapplyAllBlocking()
        }
    }

    /// Re-apply blocking from all currently active groups
    func reapplyAllBlocking() {
        // Clear first
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomainCategories = nil

        let activeIDs = ScreenTimeShared.getActiveGroupIDs()

        var allApps = Set<ApplicationToken>()
        var allCategories = Set<ActivityCategoryToken>()

        for id in activeIDs {
            if let selection = ScreenTimeShared.getSelection(for: id) {
                allApps.formUnion(selection.applicationTokens)
                allCategories.formUnion(selection.categoryTokens)
            }
        }

        if !allApps.isEmpty {
            store.shield.applications = allApps
        }
        if !allCategories.isEmpty {
            store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy<Application>
                .specific(allCategories)
            store.shield.webDomainCategories = ShieldSettings.ActivityCategoryPolicy<WebDomain>
                .specific(allCategories)
        }
    }

    // MARK: - Schedule Monitoring

    /// Start monitoring a scheduled focus group
    func startScheduleMonitoring(for group: FocusGroup) {
        let activityName = DeviceActivityName(group.id.uuidString)

        // Create schedule based on group settings
        let startComponents = DateComponents(hour: group.startHour, minute: group.startMinute)
        let endComponents = DateComponents(hour: group.endHour, minute: group.endMinute)

        let schedule = DeviceActivitySchedule(
            intervalStart: startComponents,
            intervalEnd: endComponents,
            repeats: true
        )

        do {
            try activityCenter.startMonitoring(activityName, during: schedule)
        } catch {
            logger.error("Failed to start monitoring schedule: \(error)")
        }
    }

    /// Stop monitoring a scheduled focus group
    func stopScheduleMonitoring(for group: FocusGroup) {
        let activityName = DeviceActivityName(group.id.uuidString)
        activityCenter.stopMonitoring([activityName])
    }

    /// Start a timer-based focus session
    func startTimer(for group: FocusGroup, duration: Int) {
        let endDate = Date().addingTimeInterval(TimeInterval(duration * 60))
        group.timerEndDate = endDate

        // Use DeviceActivity schedule: starts now, ends at endDate
        let activityName = DeviceActivityName(group.id.uuidString)

        let now = Calendar.current.dateComponents([.hour, .minute, .second], from: Date())
        let end = Calendar.current.dateComponents(
            [.hour, .minute, .second], from: endDate)

        let schedule = DeviceActivitySchedule(
            intervalStart: now,
            intervalEnd: end,
            repeats: false
        )

        do {
            try activityCenter.startMonitoring(activityName, during: schedule)
        } catch {
            logger.error("Failed to start timer monitoring: \(error)")
        }

        // Also immediately enable blocking
        enableBlocking(for: group)
    }

    /// Stop a timer-based focus session
    func stopTimer(for group: FocusGroup) {
        group.timerEndDate = nil
        stopScheduleMonitoring(for: group)
        disableBlocking(for: group)
    }

    // MARK: - Group Toggle

    /// Toggle a focus group on or off — handles all schedule types
    func toggleGroup(_ group: FocusGroup, enabled: Bool) {
        group.isEnabled = enabled

        if enabled {
            switch group.scheduleType {
            case .manual:
                enableBlocking(for: group)
            case .scheduled:
                enableBlocking(for: group)
                startScheduleMonitoring(for: group)
            case .timer:
                startTimer(for: group, duration: group.timerDuration)
            }
        } else {
            switch group.scheduleType {
            case .manual:
                disableBlocking(for: group)
            case .scheduled:
                stopScheduleMonitoring(for: group)
                disableBlocking(for: group)
            case .timer:
                stopTimer(for: group)
            }
        }
    }

    /// Remove a focus group entirely — disable everything and clean up
    func removeGroup(_ group: FocusGroup) {
        if group.isEnabled {
            toggleGroup(group, enabled: false)
        }
        ScreenTimeShared.removeSelection(for: group.id)
    }

    // MARK: - Selection Management

    /// Update the stored app selection for a group
    func updateSelection(for group: FocusGroup, selection: FamilyActivitySelection) {
        let data = ScreenTimeShared.encode(selection)
        group.selectedAppTokens = data
        ScreenTimeShared.storeSelection(selection, for: group.id)

        // If currently enabled, re-apply blocking
        if group.isEnabled {
            reapplyAllBlocking()
        }
    }

    /// Load the selection for a group into the picker state
    func loadSelection(for group: FocusGroup) {
        if let data = group.selectedAppTokens,
            let selection = ScreenTimeShared.decode(data)
        {
            activitySelection = selection
        } else {
            activitySelection = FamilyActivitySelection()
        }
    }
}

// MARK: - Authorization Status

enum AuthorizationStatus {
    case notDetermined
    case approved
    case denied
}
