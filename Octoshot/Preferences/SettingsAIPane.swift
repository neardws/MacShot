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
    @State private var downloadStatus: [EmbeddedModelID: String] = [:]
    @State private var downloadFraction: [EmbeddedModelID: Double] = [:]
    @State private var downloading: EmbeddedModelID?

    var body: some View {
        SettingsFormContainer {
            SettingsPaneHeader(
                title: "AI",
                subtitle: "On-device SmolVLM2 + pix2tex LaTeX specialist; optional Ollama fallback",
                systemImage: "brain"
            )

            Section {
                Toggle("Use on-device vision model (SmolVLM2)", isOn: $settings.embeddedAIUseOnDeviceVLM)
                modelRow(.smolVLM2_500M_4bit)
                modelRow(.pix2texMFR_Q4)
                Text("Weights download to \(EmbeddedAIModelPaths.modelsRoot().path) and are never bundled in the app.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Label("Embedded models", systemImage: "internaldrive")
            }

            Section {
                Toggle("Ollama fallback (OpenAI-compatible)", isOn: $settings.embeddedAIOllamaFallbackEnabled)
                HStack {
                    Circle()
                        .fill(ollamaReachable ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    Text(ollamaStatus)
                    Spacer()
                    Button(isChecking ? "Checking…" : "Test Ollama") {
                        Task { await refreshOllama() }
                    }
                    .disabled(isChecking)
                }
                if settings.embeddedAIOllamaFallbackEnabled {
                    TextField("Base URL", text: $baseURL)
                    TextField("Vision model", text: $model)
                    SecureField("API key (optional)", text: $apiKey)
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
                        Text(pullStatus).font(.caption).foregroundStyle(.secondary)
                    }
                } else {
                    Text("Enable only if you want cloud-free Ollama when embedded models are missing or MLX is unavailable.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Label("Ollama (optional)", systemImage: "server.rack")
            }

            Section {
                TextField("LaTeX prompt (VLM fallback)", text: $latexPrompt, axis: .vertical)
                    .lineLimit(3...6)
                Text("Formula mode uses pix2tex-mfr first, then SmolVLM2, then Ollama if enabled.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
            } header: {
                Label("Clips library", systemImage: "photo.stack")
            }
        }
        .onAppear(perform: loadFields)
        .onDisappear(perform: persist)
        .onReceive(NotificationCenter.default.publisher(for: .octoshotModelDownloadProgress)) { note in
            guard let progress = note.object as? ModelDownloadProgress else { return }
            downloadFraction[progress.model] = progress.fraction
            downloadStatus[progress.model] = progress.status
            if progress.fraction >= 1 {
                downloading = nil
            }
        }
    }

    @ViewBuilder
    private func modelRow(_ id: EmbeddedModelID) -> some View {
        let installed = EmbeddedAIModelPaths.isInstalled(id)
        let bytes = EmbeddedAIModelPaths.diskUsageBytes(for: id)
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: installed ? "checkmark.circle.fill" : "arrow.down.circle")
                    .foregroundStyle(installed ? .green : .secondary)
                Text(id.displayName)
                Spacer()
                Text(installed ? byteString(bytes) : "~\(id.approximateSizeMB) MB")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let status = downloadStatus[id], downloading == id || !status.isEmpty {
                ProgressView(value: downloadFraction[id] ?? 0)
                Text(status).font(.caption2).foregroundStyle(.secondary)
            }
            HStack {
                Button(downloading == id ? "Downloading…" : (installed ? "Re-download" : "Download")) {
                    Task { await downloadModel(id) }
                }
                .disabled(downloading != nil)
                if installed {
                    Button("Delete") {
                        try? ModelDownloadService.shared.delete(id)
                    }
                }
            }
            Text(id.licenseNote).font(.caption2).foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func byteString(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
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
    private func downloadModel(_ id: EmbeddedModelID) async {
        downloading = id
        downloadStatus[id] = "Starting…"
        do {
            try await ModelDownloadService.shared.download(id)
            downloadStatus[id] = "Ready"
        } catch {
            downloadStatus[id] = error.localizedDescription
            downloading = nil
        }
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
        } else {
            ollamaModels = []
            ollamaStatus = "Ollama not reachable."
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
