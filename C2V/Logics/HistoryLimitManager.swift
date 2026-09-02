//
//  HistoryLimitManager.swift
//  C2V
//

import Foundation

/// Manages clipboard history capacity limits and default settings.
@MainActor
enum HistoryLimitManager {
    static let historyLimitKey = "historyLimit"
    static let defaultLimit = 50
    static let minLimit = 10
    static let maxLimit = 100

    /// Returns the currently configured history size limit from UserDefaults.
    static var currentLimit: Int {
        let storedValue = UserDefaults.standard.integer(forKey: historyLimitKey)
        if storedValue >= minLimit, storedValue <= maxLimit {
            return storedValue
        }
        return defaultLimit
    }

    /// Sets the initial default history limit to 50 if not already configured.
    static func setupDefaultLimitIfNeeded(userDefaults: UserDefaults = .standard) {
        guard userDefaults.object(forKey: historyLimitKey) == nil else {
            return
        }
        userDefaults.set(defaultLimit, forKey: historyLimitKey)
    }
}
