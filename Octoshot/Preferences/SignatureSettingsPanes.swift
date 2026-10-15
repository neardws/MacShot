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
        Form {
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
        .formStyle(.grouped)
        .padding()
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

struct AISettingsPane: View {
    @State private var baseURL = AppSettings.shared.aiBaseURL.absoluteString
    @State private var model = AppSettings.shared.aiVisionModel
    @State private var apiKey = AppSettings.shared.aiAPIKey
    @State private var latexPrompt = AppSettings.shared.aiLatexPrompt
    @State private var clipsPath = AppSettings.shared.clipsLibraryDirectory.path

    var body: some View {
        Form {
            Text("Local OpenAI-compatible endpoint (default Ollama). Traffic does not leave your Mac unless you point elsewhere.")
                .font(.caption)
                .foregroundStyle(.secondary)

            TextField("Base URL", text: $baseURL)
            TextField("Vision model", text: $model)
            SecureField("API key (optional)", text: $apiKey)

            Section("LaTeX") {
                TextField("LaTeX prompt", text: $latexPrompt, axis: .vertical)
                    .lineLimit(4...8)
            }

            Section("Clips Library") {
                HStack {
                    Text(clipsPath).lineLimit(1).truncationMode(.middle)
                    Button("Choose…") { chooseClipsFolder() }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .onDisappear(perform: persist)
    }

    private func persist() {
        if let url = URL(string: baseURL) { AppSettings.shared.aiBaseURL = url }
        AppSettings.shared.aiVisionModel = model
        AppSettings.shared.aiAPIKey = apiKey
        AppSettings.shared.aiLatexPrompt = latexPrompt
    }

    private func chooseClipsFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.directoryURL = AppSettings.shared.clipsLibraryDirectory
        if panel.runModal() == .OK, let url = panel.url {
            AppSettings.shared.clipsLibraryDirectory = url
            clipsPath = url.path
        }
    }
}
