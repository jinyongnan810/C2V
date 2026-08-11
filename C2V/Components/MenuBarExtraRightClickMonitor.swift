//
//  MenuBarExtraRightClickMonitor.swift
//  C2V
//

import AppKit
import SwiftUI

/// Singleton manager monitoring mouse click events to display native right-click status bar context menus.
final class MenuBarExtraRightClickMonitor: NSObject {
    static let shared = MenuBarExtraRightClickMonitor()

    private var eventMonitor: Any?

    var onOpenSettings: (() -> Void)?

    override private init() {
        super.init()
    }

    /// Registers a local NSEvent monitor for right-click and Ctrl+left-click events on the status bar icon.
    func startMonitoring() {
        guard eventMonitor == nil else { return }

        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.rightMouseDown, .leftMouseDown]) { [weak self] event in
            guard let self else { return event }

            let isRightClick = event.type == .rightMouseDown
            let isControlLeftClick = event.type == .leftMouseDown && event.modifierFlags.contains(.control)

            guard isRightClick || isControlLeftClick else {
                return event
            }

            guard let window = event.window,
                  let statusBarButton = findStatusBarButton(in: window)
            else {
                return event
            }

            showContextMenu(for: statusBarButton, with: event)
            return nil
        }
    }

    /// Removes active NSEvent monitor and stops status bar click listening.
    func stopMonitoring() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    deinit {
        stopMonitoring()
    }

    /// Finds the status bar button inside the specified window's content view hierarchy.
    private func findStatusBarButton(in window: NSWindow) -> NSStatusBarButton? {
        guard let contentView = window.contentView else { return nil }
        return findStatusBarButton(in: contentView)
    }

    /// Recursively traverses view hierarchy to locate the target NSStatusBarButton instance.
    private func findStatusBarButton(in view: NSView) -> NSStatusBarButton? {
        if let button = view as? NSStatusBarButton {
            return button
        }
        for subview in view.subviews {
            if let button = findStatusBarButton(in: subview) {
                return button
            }
        }
        return nil
    }

    /// Constructs and pops up native NSMenu containing Settings and Quit menu items.
    private func showContextMenu(for button: NSStatusBarButton, with event: NSEvent) {
        let menu = NSMenu()

        let settingsTitle = NSLocalizedString("Settings", comment: "Menu item to open Settings")
        let settingsItem = NSMenuItem(
            title: settingsTitle,
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let quitTitle = NSLocalizedString("Quit C2V", comment: "Menu item to quit C2V")
        let quitItem = NSMenuItem(
            title: quitTitle,
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        button.isHighlighted = true
        NSMenu.popUpContextMenu(menu, with: event, for: button)
        button.isHighlighted = false
    }

    /// Triggers registered open settings callback.
    @objc private func openSettings() {
        onOpenSettings?()
    }

    /// Terminates the application cleanly.
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
