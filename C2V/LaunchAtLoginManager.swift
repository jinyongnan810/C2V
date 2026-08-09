//
//  LaunchAtLoginManager.swift
//  C2V
//

import Foundation
import Observation
import ServiceManagement

@MainActor
@Observable
final class LaunchAtLoginManager {
    var isEnabled: Bool = false

    init() {
        checkStatus()
    }

    func checkStatus() {
        if #available(macOS 13.0, *) {
            isEnabled = (SMAppService.mainApp.status == .enabled)
        }
    }

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
