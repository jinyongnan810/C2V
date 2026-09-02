//
//  SettingsView.swift
//  C2V
//

import SwiftData
import SwiftUI

/// Settings window view for configuring launch-at-login, history capacity limits, and accessing privacy policy links.
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ClipboardMonitor.self) private var monitor: ClipboardMonitor
    @State private var launchAtLogin = LaunchAtLoginManager()
    @AppStorage(HistoryLimitManager.historyLimitKey) private var historyLimit: Int = HistoryLimitManager.defaultLimit

    /// Renders grouped form layout with auto-start toggle, storage limit slider, and privacy policy link.
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
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("History Limit")
                            .font(.body)
                            .fontWeight(.medium)
                        Spacer()
                        Text("\(historyLimit) items")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }

                    Slider(
                        value: Binding(
                            get: { Double(historyLimit) },
                            set: { newValue in
                                historyLimit = Int(newValue.rounded())
                            }
                        ),
                        in: Double(HistoryLimitManager.minLimit) ... Double(HistoryLimitManager.maxLimit),
                        step: 10
                    ) {
                        Text("History Limit")
                    } minimumValueLabel: {
                        Text("\(HistoryLimitManager.minLimit)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } maximumValueLabel: {
                        Text("\(HistoryLimitManager.maxLimit)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .labelsHidden()

                    Text("Stores up to \(historyLimit) unpinned text snippets locally on your Mac. Files and images are excluded.")
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

                    Link(destination: privacyPolicyURL) {
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
        .frame(width: 380, height: 410)
        .onAppear {
            launchAtLogin.checkStatus()
        }
        .onDisappear {
            monitor.trimOldItemsIfNeeded(modelContext: modelContext, maxLimit: historyLimit)
        }
    }

    /// Resolves localized privacy policy document URL based on current system language preference.
    private var privacyPolicyURL: URL {
        let isJapanese = Locale.preferredLanguages.first?.hasPrefix("ja") == true || Locale.current.language.languageCode?.identifier == "ja"
        let fileName = isJapanese ? "PRIVACY_POLICY_JA.md" : "PRIVACY_POLICY.md"
        return URL(string: "https://github.com/jinyongnan810/C2V/blob/main/\(fileName)")!
    }
}

#Preview {
    SettingsView()
        .environment(ClipboardMonitor())
        .modelContainer(for: CopiedItem.self, inMemory: true)
}
