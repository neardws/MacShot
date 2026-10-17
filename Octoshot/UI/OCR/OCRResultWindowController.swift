import AppKit
import SwiftUI
import OctoshotCore

@MainActor
final class OCRResultWindowController {
    private var window: NSWindow?

    func show(image: NSImage) {
        let view = OCRResultView(image: image)
        let hosting = NSHostingController(rootView: view)
        if window == nil {
            let window = NSWindow(contentViewController: hosting)
            window.title = OctoshotL10n.ocrWindowTitle
            window.setContentSize(NSSize(width: 720, height: 520))
            window.center()
            self.window = window
        } else {
            window?.contentViewController = hosting
            window?.title = OctoshotL10n.ocrWindowTitle
        }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct OCRResultView: View {
    let image: NSImage
    @State private var recognizedText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var textView: NSTextView?

    var body: some View {
        HSplitView {
            VStack(alignment: .leading, spacing: 12) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 360)
                Button(isLoading ? OctoshotL10n.ocrRecognizing : OctoshotL10n.ocrRecognizeAgain) {
                    Task { await recognize() }
                }
                .disabled(isLoading)
            }
            .frame(minWidth: 260)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Button(OctoshotL10n.ocrSelectAll) {
                        textView?.selectAll(nil)
                        if let textView {
                            textView.window?.makeFirstResponder(textView)
                        }
                    }
                    .disabled(recognizedText.isEmpty)
                    Button(OctoshotL10n.ocrCopy) {
                        copyToPasteboard()
                    }
                    .disabled(recognizedText.isEmpty)
                    .keyboardShortcut("c", modifiers: .command)
                    Spacer()
                }

                SelectableTextView(text: $recognizedText) { view in
                    textView = view
                }
                .frame(minHeight: 280)

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.callout)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding()
        .task {
            await recognize()
        }
    }

    @MainActor
    private func recognize() async {
        isLoading = true
        errorMessage = nil
        recognizedText = ""
        defer { isLoading = false }
        do {
            let result = try await OCRService.recognizeText(in: image)
            let trimmed = result.text.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                errorMessage = OctoshotL10n.ocrNoTextFound
            } else {
                recognizedText = result.text
            }
        } catch {
            errorMessage = "\(OctoshotL10n.ocrRecognitionFailed) \(error.localizedDescription)"
        }
    }

    private func copyToPasteboard() {
        guard !recognizedText.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(recognizedText, forType: .string)
    }
}

/// AppKit text view so Select All and selection behave predictably on macOS 14.
struct SelectableTextView: NSViewRepresentable {
    @Binding var text: String
    var onTextViewCreated: (NSTextView) -> Void

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        textView.isEditable = false
        textView.isSelectable = true
        textView.font = .systemFont(ofSize: NSFont.systemFontSize)
        textView.textContainer?.widthTracksTextView = true
        textView.string = text
        onTextViewCreated(textView)
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        if textView.string != text {
            textView.string = text
        }
    }
}
