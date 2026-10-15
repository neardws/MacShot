import AppKit
import SwiftUI

enum AIAssistantAction: String, CaseIterable, Identifiable {
    case explain
    case summarize
    case translateChinese
    case translateEnglish
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .explain: return "Explain"
        case .summarize: return "Summarize"
        case .translateChinese: return "Translate → 中文"
        case .translateEnglish: return "Translate → English"
        case .custom: return "Custom"
        }
    }

    func prompt(custom: String) -> String {
        switch self {
        case .explain: return AIPrompts.explain()
        case .summarize: return AIPrompts.summarize()
        case .translateChinese: return AIPrompts.translate(to: "Simplified Chinese")
        case .translateEnglish: return AIPrompts.translate(to: "English")
        case .custom: return custom
        }
    }
}

@MainActor
final class AIAssistantModel: ObservableObject {
    @Published var output = ""
    @Published var isStreaming = false
    @Published var customPrompt = ""
    @Published var selectedAction: AIAssistantAction = .explain
    @Published var errorMessage: String?

    private var task: Task<Void, Never>?

    func run(image: NSImage) {
        task?.cancel()
        output = ""
        errorMessage = nil
        isStreaming = true
        let prompt = selectedAction.prompt(custom: customPrompt)
        let client = OpenAICompatibleClient.fromSettings()
        task = Task {
            do {
                for try await chunk in client.streamVisionChat(prompt: prompt, image: image) {
                    output += chunk
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isStreaming = false
        }
    }

    func stop() {
        task?.cancel()
        isStreaming = false
    }
}

struct AIAssistantPanelView: View {
    let image: NSImage
    @StateObject private var model = AIAssistantModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Local AI")
                .font(.headline)
            Text("Requests stay on your machine via the configured OpenAI-compatible endpoint.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Picker("Action", selection: $model.selectedAction) {
                ForEach(AIAssistantAction.allCases) { action in
                    Text(action.title).tag(action)
                }
            }

            if model.selectedAction == .custom {
                TextField("Custom prompt", text: $model.customPrompt, axis: .vertical)
                    .lineLimit(3...6)
            }

            HStack {
                Button(model.isStreaming ? "Stop" : "Run") {
                    if model.isStreaming { model.stop() } else { model.run(image: image) }
                }
                .disabled(model.selectedAction == .custom && model.customPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                if model.isStreaming {
                    ProgressView().controlSize(.small)
                }
            }

            if let errorMessage = model.errorMessage {
                Text(errorMessage).foregroundStyle(.red).font(.caption)
            }

            ScrollView {
                Text(model.output.isEmpty ? "Response will stream here…" : model.output)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .frame(minHeight: 180)
        }
        .padding(12)
        .frame(width: 320)
    }
}
