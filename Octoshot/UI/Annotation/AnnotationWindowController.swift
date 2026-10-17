import AppKit
import SwiftUI
import OctoshotCore

@MainActor
final class AnnotationWindowController {
    private let window: NSWindow
    private var canvasView: AnnotationCanvasView?
    private let toolbarModel = AnnotationToolbarModel()
    private var aiPanel: NSPanel?
    private var redactionPanel: NSPanel?
    private var redactionCandidates: [RedactionCandidate] = []
    private var currentImage: NSImage?
    private var lastSavedURL: URL?

    init() {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1100, height: 640),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Octoshot — Annotate"
        window.center()
        setupContent()
    }

    func open(with image: NSImage) {
        currentImage = image
        canvasView?.baseImage = image
        canvasView?.strokes = []
        canvasView?.redactionRegions = []
        canvasView?.previewRedactions = []
        canvasView?.resetHistory()
        canvasView?.strokeColor = toolbarModel.strokeNSColor
        canvasView?.lineWidth = toolbarModel.lineWidth
        canvasView?.rebuildComposite()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        if AppSettings.shared.autoRedactOnAnnotate {
            Task { await runAutoRedactPreview() }
        }
    }

    private func setupContent() {
        let canvas = AnnotationCanvasView()
        canvas.translatesAutoresizingMaskIntoConstraints = false
        canvasView = canvas

        toolbarModel.onTool = { [weak canvas] tool in canvas?.activeTool = tool }
        toolbarModel.onColor = { [weak canvas] color in canvas?.strokeColor = color }
        toolbarModel.onLineWidth = { [weak canvas] width in canvas?.lineWidth = width }
        toolbarModel.onUndo = { [weak canvas, weak toolbarModel] in
            canvas?.undo()
            if let canvas { toolbarModel?.refreshUndoRedoState(from: canvas) }
        }
        toolbarModel.onRedo = { [weak canvas, weak toolbarModel] in
            canvas?.redo()
            if let canvas { toolbarModel?.refreshUndoRedoState(from: canvas) }
        }
        canvas.onStrokesChanged = { [weak self] in
            self?.toolbarModel.refreshUndoRedoState(from: canvas)
        }
        toolbarModel.refreshUndoRedoState(from: canvas)
        toolbarModel.onCopy = { [weak self] in self?.copyImage() }
        toolbarModel.onSave = { [weak self] in self?.saveImage() }
        toolbarModel.onPin = { [weak self] in self?.pinImage() }
        toolbarModel.onAutoRedact = { [weak self] in Task { await self?.runAutoRedactPreview() } }
        toolbarModel.onAskAI = { [weak self] in self?.toggleAIPanel() }
        toolbarModel.onCopyMarkdown = { [weak self] in self?.copyMarkdown() }
        toolbarModel.onCopyPath = { [weak self] in self?.copyFilePath() }

        let toolbar = NSHostingView(rootView: AnnotationToolbarView(model: toolbarModel))
        toolbar.translatesAutoresizingMaskIntoConstraints = false

        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(toolbar)
        container.addSubview(canvas)

        NSLayoutConstraint.activate([
            toolbar.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            toolbar.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            toolbar.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            toolbar.heightAnchor.constraint(equalToConstant: 52),

            canvas.topAnchor.constraint(equalTo: toolbar.bottomAnchor, constant: 8),
            canvas.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            canvas.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            canvas.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
        ])

        window.contentView = container
        window.makeFirstResponder(canvas)
    }

    private func toggleAIPanel() {
        guard let image = currentImage else { return }
        if let aiPanel {
            aiPanel.close()
            self.aiPanel = nil
            return
        }
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 480),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        panel.title = "Ask Local AI"
        panel.isFloatingPanel = true
        panel.contentView = NSHostingView(rootView: AIAssistantPanelView(image: image))
        panel.center()
        panel.makeKeyAndOrderFront(nil)
        aiPanel = panel
    }

    private func runAutoRedactPreview() async {
        guard let image = currentImage else { return }
        do {
            redactionCandidates = try await RedactionDetector.detect(in: image)
            canvasView?.previewRedactions = redactionCandidates
            showRedactionReview()
        } catch {
            NSAlert(error: error).runModal()
        }
    }

    private func showRedactionReview() {
        redactionPanel?.close()
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 380, height: 360),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        panel.title = "Auto Redact"
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        let view = RedactionReviewView(
            candidates: Binding(
                get: { self.redactionCandidates },
                set: { self.redactionCandidates = $0; self.canvasView?.previewRedactions = $0 }
            ),
            onApply: { [weak self] in
                self?.canvasView?.applyRedactions(from: self?.redactionCandidates ?? [])
                self?.redactionPanel?.close()
            },
            onCancel: { [weak self] in
                self?.canvasView?.previewRedactions = []
                self?.redactionPanel?.close()
            }
        )
        panel.contentView = NSHostingView(rootView: view)
        panel.center()
        panel.makeKeyAndOrderFront(nil)
        redactionPanel = panel
    }

    private func copyImage() {
        guard let image = canvasView?.currentImage() else { return }
        ImageFormats.copyToPasteboard(image)
    }

    private func pinImage() {
        guard let image = canvasView?.currentImage() else { return }
        PinnedScreenshotManager.shared.pin(image: image)
    }

    private func saveImage() {
        guard let image = canvasView?.currentImage() else { return }
        let url = AppSettings.shared.defaultSaveURL(prefix: "Annotated")
        do {
            try ImageFormats.write(
                image: image,
                to: url,
                format: AppSettings.shared.format,
                jpegQuality: AppSettings.shared.jpegQuality
            )
            lastSavedURL = url
        } catch {
            NSAlert(error: error).runModal()
        }
    }

    private func copyMarkdown() {
        guard let image = canvasView?.currentImage() else { return }
        do {
            let url = try DeveloperClipboard.copyMarkdownSnippet(for: image, existingURL: lastSavedURL)
            lastSavedURL = url
        } catch {
            NSAlert(error: error).runModal()
        }
    }

    private func copyFilePath() {
        guard let image = canvasView?.currentImage() else { return }
        do {
            let url = try DeveloperClipboard.copyFilePath(for: image, existingURL: lastSavedURL)
            lastSavedURL = url
        } catch {
            NSAlert(error: error).runModal()
        }
    }
}

@MainActor
final class AnnotationToolbarModel: ObservableObject {
    @Published var selectedTool: AnnotationTool = .arrow
    @Published var strokeColor: Color = Color(nsColor: .systemRed)
    @Published var lineWidth: CGFloat = 4
    @Published var canRedo = false

    var strokeNSColor: NSColor { NSColor(strokeColor) }

    var onTool: ((AnnotationTool) -> Void)?
    var onColor: ((NSColor) -> Void)?
    var onLineWidth: ((CGFloat) -> Void)?
    var onUndo: (() -> Void)?
    var onRedo: (() -> Void)?
    var onCopy: (() -> Void)?
    var onSave: (() -> Void)?
    var onPin: (() -> Void)?
    var onAutoRedact: (() -> Void)?
    var onAskAI: (() -> Void)?
    var onCopyMarkdown: (() -> Void)?
    var onCopyPath: (() -> Void)?

    func select(_ tool: AnnotationTool) {
        selectedTool = tool
        onTool?(tool)
    }

    func refreshUndoRedoState(from canvas: AnnotationCanvasView) {
        canRedo = canvas.canRedo
    }
}

struct AnnotationToolbarView: View {
    @ObservedObject var model: AnnotationToolbarModel
    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        HStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(AnnotationTool.visibleTools(developerMode: settings.developerModeEnabled)) { tool in
                        Button {
                            model.select(tool)
                        } label: {
                            Image(systemName: tool.symbol)
                                .frame(width: 30, height: 26)
                                .background(model.selectedTool == tool ? Color.accentColor.opacity(0.25) : .clear)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                        .help(tool.label)
                    }
                }
            }
            .frame(maxWidth: 520)

            ColorPicker("", selection: $model.strokeColor, supportsOpacity: false)
                .labelsHidden()
                .frame(width: 28, height: 28)
                .help("Stroke color")
                .onChange(of: model.strokeColor) { _, newValue in
                    model.onColor?(NSColor(newValue))
                }

            Menu {
                ForEach(AnnotationStrokeStyle.presetWidths, id: \.self) { width in
                    Button("\(Int(width)) pt") {
                        model.lineWidth = width
                        model.onLineWidth?(width)
                    }
                }
            } label: {
                Label("\(Int(model.lineWidth))", systemImage: "lineweight")
                    .labelStyle(.titleAndIcon)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .help("Stroke width")

            HStack(spacing: 3) {
                ForEach(Array(AnnotationStrokeStyle.presetColors.enumerated()), id: \.offset) { _, color in
                    Button {
                        model.strokeColor = Color(nsColor: color)
                        model.onColor?(color)
                    } label: {
                        Circle()
                            .fill(Color(nsColor: color))
                            .frame(width: 14, height: 14)
                            .overlay(Circle().stroke(Color.primary.opacity(0.2), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer(minLength: 8)

            Button("Auto Redact") { model.onAutoRedact?() }
            Button("Ask AI") { model.onAskAI?() }
            if settings.developerModeEnabled {
                Button("Copy MD") { model.onCopyMarkdown?() }
                    .help("Copy Markdown image snippet for GitHub issues")
                Button("Copy Path") { model.onCopyPath?() }
            }
            Button("Undo") { model.onUndo?() }
                .keyboardShortcut("z", modifiers: .command)
            Button("Redo") { model.onRedo?() }
                .disabled(!model.canRedo)
                .keyboardShortcut("z", modifiers: [.command, .shift])
            Button("贴图") { model.onPin?() }
                .help("贴图 / Pin to screen")
            Button("Copy") { model.onCopy?() }
            Button("Save") { model.onSave?() }
        }
    }
}
