//
//  ScreenTimeShared.swift
//  Cleansed
//
//  Created by Nguyen Trong Dat on 2/23/26.
//

import FamilyControls
import Foundation

/// Shared constants and utilities for Screen Time integration across main app and extensions.
struct ScreenTimeShared {

    /// App Group identifier for sharing data between main app and extensions.
    static let appGroupID = "group.com.cleansed.shared"

    /// UserDefaults suite shared via App Group.
    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    // MARK: - Keys

    /// Key for storing the active focus group IDs (as JSON array of UUID strings)
    static let activeGroupIDsKey = "activeGroupIDs"

    /// Key prefix for storing encoded FamilyActivitySelection per group
    static let selectionKeyPrefix = "focusGroupSelection_"

    // MARK: - FamilyActivitySelection Encoding/Decoding

    /// Encode a FamilyActivitySelection to Data for persistence
    static func encode(_ selection: FamilyActivitySelection) -> Data? {
        try? JSONEncoder().encode(selection)
    }

    /// Decode a FamilyActivitySelection from Data
    static func decode(_ data: Data) -> FamilyActivitySelection? {
        try? JSONDecoder().decode(FamilyActivitySelection.self, from: data)
    }

    // MARK: - Active Groups

    /// Store active group IDs to shared UserDefaults so extensions can read them
    static func setActiveGroupIDs(_ ids: [UUID]) {
        let strings = ids.map { $0.uuidString }
        sharedDefaults?.set(strings, forKey: activeGroupIDsKey)
    }

    /// Read active group IDs from shared UserDefaults
    static func getActiveGroupIDs() -> [UUID] {
        guard let strings = sharedDefaults?.stringArray(forKey: activeGroupIDsKey) else {
            return []
        }
        return strings.compactMap { UUID(uuidString: $0) }
    }

    /// Store a FamilyActivitySelection for a group ID in shared defaults
    static func storeSelection(_ selection: FamilyActivitySelection, for groupID: UUID) {
        let key = selectionKeyPrefix + groupID.uuidString
        if let data = encode(selection) {
            sharedDefaults?.set(data, forKey: key)
        }
    }

    /// Retrieve a FamilyActivitySelection for a group ID from shared defaults
    static func getSelection(for groupID: UUID) -> FamilyActivitySelection? {
        let key = selectionKeyPrefix + groupID.uuidString
        guard let data = sharedDefaults?.data(forKey: key) else { return nil }
        return decode(data)
    }

    /// Remove stored selection for a group ID
    static func removeSelection(for groupID: UUID) {
        let key = selectionKeyPrefix + groupID.uuidString
        sharedDefaults?.removeObject(forKey: key)
    }
}
