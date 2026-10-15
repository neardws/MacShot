import SwiftUI
import OctoshotCore

struct RedactionSettingsPane: View {
    @State private var autoRedact = AppSettings.shared.autoRedactOnAnnotate
    @State private var phones = AppSettings.shared.redactPhones
    @State private var emails = AppSettings.shared.redactEmails
    @State private var nationalIDs = AppSettings.shared.redactNationalIDs
    @State private var cards = AppSettings.shared.redactCreditCards
    @State private var apiKeys = AppSettings.shared.redactAPIKeys
    @State private var ips = AppSettings.shared.redactIPAddresses
    @State private var faces = AppSettings.shared.redactFaces

    var body: some View {
        Group {
            Toggle("Auto-apply when opening Annotate", isOn: $autoRedact)
            Text("Detection runs on-device with Apple Vision (text + faces).")
                .font(.caption)
                .foregroundStyle(.secondary)

            Section("Detect") {
                Toggle("Phone numbers (incl. China mobile)", isOn: $phones)
                Toggle("Email addresses", isOn: $emails)
                Toggle("ID card numbers", isOn: $nationalIDs)
                Toggle("Credit card numbers", isOn: $cards)
                Toggle("API keys / tokens", isOn: $apiKeys)
                Toggle("IP addresses", isOn: $ips)
                Toggle("Faces", isOn: $faces)
            }
        }
        .onChange(of: autoRedact) { _, v in AppSettings.shared.autoRedactOnAnnotate = v }
        .onChange(of: phones) { _, v in AppSettings.shared.redactPhones = v }
        .onChange(of: emails) { _, v in AppSettings.shared.redactEmails = v }
        .onChange(of: nationalIDs) { _, v in AppSettings.shared.redactNationalIDs = v }
        .onChange(of: cards) { _, v in AppSettings.shared.redactCreditCards = v }
        .onChange(of: apiKeys) { _, v in AppSettings.shared.redactAPIKeys = v }
        .onChange(of: ips) { _, v in AppSettings.shared.redactIPAddresses = v }
        .onChange(of: faces) { _, v in AppSettings.shared.redactFaces = v }
    }
}
