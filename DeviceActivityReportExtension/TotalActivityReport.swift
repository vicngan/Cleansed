//
//  TotalActivityReport.swift
//  DeviceActivityReportExtension
//
//  Created by Nguyen Trong Dat on 2/23/26.
//

import DeviceActivity
import ExtensionKit
import ManagedSettings
import SwiftUI

extension DeviceActivityReport.Context {
    static let totalActivity = Self("Total Activity")
}

/// Data model for the report
struct ActivityReportData: Sendable {
    let totalDuration: TimeInterval
    let apps: [AppUsageData]
}

struct AppUsageData: Identifiable, Sendable {
    let id = UUID()
    let name: String
    let duration: TimeInterval

    var formattedDuration: String { formatScreenTimeDuration(duration) }
}

func formatScreenTimeDuration(_ interval: TimeInterval) -> String {
    let hours = Int(interval) / 3600
    let minutes = (Int(interval) % 3600) / 60
    if hours > 0 {
        return "\(hours)h \(minutes)m"
    }
    return "\(minutes)m"
}

struct TotalActivityReport: DeviceActivityReportScene {
    let context: DeviceActivityReport.Context = .totalActivity

    let content: (ActivityReportData) -> TotalActivityView

    nonisolated func makeConfiguration(representing data: DeviceActivityResults<DeviceActivityData>)
        async
        -> ActivityReportData
    {
        var totalDuration: TimeInterval = 0
        var appUsages: [AppUsageData] = []

        for await activityData in data {
            for await segment in activityData.activitySegments {
                totalDuration += segment.totalActivityDuration

                for await categoryData in segment.categories {
                    for await app in categoryData.applications {
                        let appName = app.application.localizedDisplayName ?? "Unknown"
                        let duration = app.totalActivityDuration
                        if duration > 0 {
                            appUsages.append(AppUsageData(name: appName, duration: duration))
                        }
                    }
                }
            }
        }

        appUsages.sort { $0.duration > $1.duration }
        let topApps = Array(appUsages.prefix(10))

        return ActivityReportData(totalDuration: totalDuration, apps: topApps)
    }
}
