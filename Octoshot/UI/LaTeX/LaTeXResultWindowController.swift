import AppKit
import SwiftUI
import OctoshotCore

@MainActor
final class LaTeXResultWindowController {
    private var window: NSWindow?

    func show(image: NSImage) {
        let view = LaTeXResultView(image: image)
        let hosting = NSHostingController(rootView: view)
        if window == nil {
            let window = NSWindow(contentViewController: hosting)
            window.title = "Screenshot → LaTeX"
            window.setContentSize(NSSize(width: 720, height: 520))
            window.center()
            self.window = window
        } else {
            window?.contentViewController = hosting
        }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct LaTeXResultView: View {
    let image: NSImage
    @State private var latex = ""
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        HSplitView {
            VStack(alignment: .leading) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                Button(isLoading ? "Converting…" : "Convert to LaTeX") {
                    Task { await convert() }
                }
                .disabled(isLoading)
            }
            .frame(minWidth: 260)

            VStack(alignment: .leading) {
                HStack {
                    Button("Copy LaTeX") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(latex, forType: .string)
                    }
                    .disabled(latex.isEmpty)
                    Spacer()
                }
                TextEditor(text: $latex)
                    .font(.monospaced(.body)())
                if let error {
                    Text(error).foregroundStyle(.red).font(.caption)
                }
                GroupBox("Preview") {
                    Text(latex.isEmpty ? "Converted LaTeX will appear above. Paste into your editor or use a local Math renderer." : latex)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minHeight: 80)
            }
        }
        .padding()
    }

    @MainActor
    private func convert() async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        let client = OpenAICompatibleClient.fromSettings()
        let prompt = AppSettings.shared.aiLatexPrompt
        do {
            latex = try await client.completeVisionChat(prompt: prompt, image: image)
                .trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            self.error = error.localizedDescription
        }
    }
}
