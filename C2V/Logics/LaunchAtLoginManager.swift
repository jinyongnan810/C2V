//
//  LaunchAtLoginManager.swift
//  C2V
//

import Foundation
import Observation
import ServiceManagement

/// Helper manager using ServiceManagement framework to register or unregister launch-at-login behavior.
@MainActor
@Observable
final class LaunchAtLoginManager {
    var isEnabled: Bool = false

    /// Initializes manager and queries initial SMAppService status.
    init() {
        checkStatus()
    }

    /// Checks whether the main app login item service is currently enabled in macOS settings.
    func checkStatus() {
        if #available(macOS 13.0, *) {
            isEnabled = (SMAppService.mainApp.status == .enabled)
        }
    }

    /// Registers or unregisters the app service with SMAppService based on user setting preference.
    func setLaunchAtLogin(enabled: Bool) {
        if #available(macOS 13.0, *) {
            do {
                if enabled, SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                } else if !enabled, SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
                checkStatus()
            } catch {
                print("Failed to set Launch at Login: \(error)")
            }
        }
    }
}
