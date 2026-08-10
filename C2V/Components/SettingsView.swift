//
//  SettingsView.swift
//  C2V
//

import SwiftUI

struct SettingsView: View {
    @State private var launchAtLogin = LaunchAtLoginManager()

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
                    Text("Stores up to 100 unpinned text snippets locally on your Mac. Files and images are excluded.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Clipboard Storage")
                    .font(.headline)
            }

            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("All clipboard history is stored strictly on your local device. C2V does not collect, track, or transmit any data.")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Link(destination: URL(string: "https://github.com/jinyongnan810/C2V/blob/main/PRIVACY_POLICY.md")!) {
                        HStack(spacing: 3) {
                            Text("View Privacy Policy")
                            Image(systemName: "arrow.up.right.square")
                        }
                        .font(.caption)
                    }
                }
            } header: {
                Text("Privacy & Security")
                    .font(.headline)
            }
        }
        .formStyle(.grouped)
        .frame(width: 380, height: 310)
        .onAppear {
            launchAtLogin.checkStatus()
        }
    }
}

#Preview {
    SettingsView()
}
