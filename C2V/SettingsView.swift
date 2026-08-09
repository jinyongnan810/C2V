//
//  SettingsView.swift
//  C2V
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var launchAtLogin = LaunchAtLoginManager()

    var body: some View {
        Form {
            Section {
                Toggle(isOn: Binding(
                    get: { launchAtLogin.isEnabled },
                    set: { launchAtLogin.setLaunchAtLogin(enabled: $0) }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Auto Start on Boot")
                            .font(.body)
                            .fontWeight(.medium)
                        Text("Launch C2V automatically when macOS starts.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .toggleStyle(.switch)
            } header: {
                Text("General")
                    .font(.headline)
            }

            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Stores up to 100 text snippets locally on your Mac. Files and images are excluded.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Clipboard Storage")
                    .font(.headline)
            }
        }
        .formStyle(.grouped)
        .frame(width: 380, height: 220)
        .onAppear {
            launchAtLogin.checkStatus()
        }
    }
}

#Preview {
    SettingsView()
}
