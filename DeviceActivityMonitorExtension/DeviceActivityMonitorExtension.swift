//
//  DeviceActivityMonitorExtension.swift
//  DeviceActivityMonitorExtension
//
//  Created by Nguyen Trong Dat on 2/23/26.
//

import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings

/// Monitors device activity schedules and applies/removes app shields.
/// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    private let store = ManagedSettingsStore()

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        guard let groupID = UUID(uuidString: activity.rawValue) else { return }
        guard let selection = ScreenTimeShared.getSelection(for: groupID) else { return }

        let applications = selection.applicationTokens
        let categories = selection.categoryTokens

        if !applications.isEmpty {
            store.shield.applications = applications
        }
        if !categories.isEmpty {
            store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy<Application>
                .specific(categories)
            store.shield.webDomainCategories = ShieldSettings.ActivityCategoryPolicy<WebDomain>
                .specific(categories)
        }

        var activeIDs = ScreenTimeShared.getActiveGroupIDs()
        if !activeIDs.contains(groupID) {
            activeIDs.append(groupID)
            ScreenTimeShared.setActiveGroupIDs(activeIDs)
        }
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        guard let groupID = UUID(uuidString: activity.rawValue) else { return }

        var activeIDs = ScreenTimeShared.getActiveGroupIDs()
        activeIDs.removeAll { $0 == groupID }
        ScreenTimeShared.setActiveGroupIDs(activeIDs)

        ScreenTimeShared.removeSelection(for: groupID)

        if activeIDs.isEmpty {
            store.shield.applications = nil
            store.shield.applicationCategories = nil
            store.shield.webDomainCategories = nil
        } else {
            reapplyAllBlocking(activeIDs: activeIDs)
        }
    }

    override func eventDidReachThreshold(
        _ event: DeviceActivityEvent.Name, activity: DeviceActivityName
    ) {
        super.eventDidReachThreshold(event, activity: activity)
    }

    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
    }

    override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillEndWarning(for: activity)
    }

    override func eventWillReachThresholdWarning(
        _ event: DeviceActivityEvent.Name, activity: DeviceActivityName
    ) {
        super.eventWillReachThresholdWarning(event, activity: activity)
    }

    private func reapplyAllBlocking(activeIDs: [UUID]) {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomainCategories = nil

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
}
