//
//  TotalActivityView.swift
//  DeviceActivityReportExtension
//
//  Created by Nguyen Trong Dat on 2/23/26.
//

import SwiftUI

struct TotalActivityView: View {
    let totalActivity: ActivityReportData

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Total screen time
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Screen Time")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(formatScreenTimeDuration(totalActivity.totalDuration))
                        .font(.title2.bold())
                }
                Spacer()
            }

            if !totalActivity.apps.isEmpty {
                Divider()

                Text("Top Apps")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(totalActivity.apps) { app in
                    HStack {
                        Text(app.name)
                            .font(.subheadline)
                            .lineLimit(1)

                        Spacer()

                        Text(app.formattedDuration)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Text("No activity data available yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
            }
        }
        .padding(16)
    }


}

#Preview {
    TotalActivityView(
        totalActivity: ActivityReportData(
            totalDuration: 5580,
            apps: [
                AppUsageData(name: "Safari", duration: 3600),
                AppUsageData(name: "Messages", duration: 1200),
                AppUsageData(name: "Instagram", duration: 780),
            ]
        ))
}
