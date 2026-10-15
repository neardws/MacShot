import AppKit
import SwiftUI
import OctoshotCore

struct SettingsAIPane: View {
    @ObservedObject private var settings = AppSettings.shared
    @State private var baseURL = ""
    @State private var model = ""
    @State private var apiKey = ""
    @State private var latexPrompt = ""
    @State private var clipsPath = ""
    @State private var ollamaModels: [OllamaModel] = []
    @State private var ollamaStatus = "Not checked"
    @State private var isChecking = false
    @State private var isPulling = false
    @State private var pullStatus = ""

    var body: some View {
        SettingsFormContainer {
            SettingsPaneHeader(
                title: "AI",
                subtitle: "Local Ollama / OpenAI-compatible vision models, LaTeX, and Clips",
                systemImage: "brain"
            )

            Section {
                HStack {
                    Circle()
                        .fill(ollamaReachable ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    Text(ollamaStatus)
                    Spacer()
                    Button(isChecking ? "Checking…" : "Test connection") {
                        Task { await refreshOllama() }
                    }
                    .disabled(isChecking)
                }

                if !ollamaModels.isEmpty {
                    Picker("Installed models", selection: $model) {
                        ForEach(ollamaModels) { m in
                            Text(m.name).tag(m.name)
                        }
                    }
                }

                Button(isPulling ? "Pulling…" : "Pull qwen2.5vl") {
                    Task { await pullRecommended() }
                }
                .disabled(isPulling)

                if !pullStatus.isEmpty {
                    Text(pullStatus)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text("Install Ollama from ollama.com, then run `ollama pull qwen2.5vl` if the button fails.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Label("Ollama", systemImage: "server.rack")
            }

            Section {
                TextField("Base URL", text: $baseURL)
                TextField("Vision model", text: $model)
                SecureField("API key (optional)", text: $apiKey)
            } header: {
                Label("Endpoint", systemImage: "link")
            }

            Section {
                TextField("LaTeX prompt", text: $latexPrompt, axis: .vertical)
                    .lineLimit(4...8)
            } header: {
                Label("LaTeX", systemImage: "function")
            }

            Section {
                HStack {
                    Text(clipsPath)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Button("Choose…") { chooseClipsFolder() }
                }
                Text("Paper figure/table captures are saved here as Clips.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Label("Clips library", systemImage: "photo.stack")
            }

        }
        .onAppear(perform: loadFields)
        .onDisappear(perform: persist)
    }

    private var ollamaReachable: Bool {
        ollamaStatus.contains("Connected")
    }

    private func loadFields() {
        baseURL = settings.aiBaseURL.absoluteString
        model = settings.aiVisionModel
        apiKey = settings.aiAPIKey
        latexPrompt = settings.aiLatexPrompt
        clipsPath = settings.clipsLibraryDirectory.path
        Task { await refreshOllama() }
    }

    private func persist() {
        if let url = URL(string: baseURL) { settings.aiBaseURL = url }
        settings.aiVisionModel = model
        settings.aiAPIKey = apiKey
        settings.aiLatexPrompt = latexPrompt
    }

    @MainActor
    private func refreshOllama() async {
        isChecking = true
        defer { isChecking = false }
        persist()
        if let models = await OllamaService.listModels(baseURL: settings.aiBaseURL) {
            ollamaModels = models
            ollamaStatus = models.isEmpty
                ? "Connected to Ollama — no models yet."
                : "Connected — \(models.count) model(s)."
            if !models.contains(where: { $0.name == model }) {
                if let first = models.first?.name { model = first }
            }
        } else {
            ollamaModels = []
            ollamaStatus = "Ollama not reachable at \(OllamaService.hostURL(from: settings.aiBaseURL).absoluteString)."
        }
    }

    @MainActor
    private func pullRecommended() async {
        isPulling = true
        pullStatus = ""
        defer { isPulling = false }
        do {
            try await OllamaService.pullModel("qwen2.5vl", baseURL: settings.aiBaseURL) { status in
                Task { @MainActor in pullStatus = status }
            }
            model = "qwen2.5vl:latest"
            settings.aiVisionModel = model
            pullStatus = "Pull finished."
            await refreshOllama()
        } catch {
            pullStatus = error.localizedDescription
        }
    }

    private func chooseClipsFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.directoryURL = settings.clipsLibraryDirectory
        if panel.runModal() == .OK, let url = panel.url {
            settings.clipsLibraryDirectory = url
            clipsPath = url.path
        }
    }
}
