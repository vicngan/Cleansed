//
//  DeviceActivityReportExtension.swift
//  DeviceActivityReportExtension
//
//  Created by Nguyen Trong Dat on 2/23/26.
//

import DeviceActivity
import ExtensionKit
import SwiftUI

@main
struct CleansedReportExtension: DeviceActivityReportExtension {
    @MainActor
    var body: some DeviceActivityReportScene {
        TotalActivityReport { totalActivity in
            TotalActivityView(totalActivity: totalActivity)
        }
    }
}
