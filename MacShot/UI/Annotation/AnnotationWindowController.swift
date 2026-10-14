import AppKit
import SwiftUI

@MainActor
final class AnnotationWindowController {
    private let window: NSWindow
    private var canvasView: AnnotationCanvasView?
    private let toolbarModel = AnnotationToolbarModel()

    init() {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 640),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Annotate"
        window.center()
        setupContent()
    }

    func open(with image: NSImage) {
        canvasView?.baseImage = image
        canvasView?.strokes = []
        canvasView?.rebuildComposite()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func setupContent() {
        let canvas = AnnotationCanvasView()
        canvas.translatesAutoresizingMaskIntoConstraints = false
        canvasView = canvas

        toolbarModel.onTool = { [weak canvas] tool in canvas?.activeTool = tool }
        toolbarModel.onUndo = { [weak canvas] in canvas?.undo() }
        toolbarModel.onCopy = { [weak self] in self?.copyImage() }
        toolbarModel.onSave = { [weak self] in self?.saveImage() }

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
            toolbar.heightAnchor.constraint(equalToConstant: 44),

            canvas.topAnchor.constraint(equalTo: toolbar.bottomAnchor, constant: 8),
            canvas.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            canvas.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
            canvas.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
        ])

        window.contentView = container
    }

    private func copyImage() {
        guard let image = canvasView?.currentImage() else { return }
        ImageFormats.copyToPasteboard(image)
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
        } catch {
            NSAlert(error: error).runModal()
        }
    }
}

@MainActor
final class AnnotationToolbarModel: ObservableObject {
    @Published var selectedTool: AnnotationTool = .arrow
    var onTool: ((AnnotationTool) -> Void)?
    var onUndo: (() -> Void)?
    var onCopy: (() -> Void)?
    var onSave: (() -> Void)?

    func select(_ tool: AnnotationTool) {
        selectedTool = tool
        onTool?(tool)
    }
}

struct AnnotationToolbarView: View {
    @ObservedObject var model: AnnotationToolbarModel

    var body: some View {
        HStack {
            ForEach(AnnotationTool.allCases) { tool in
                Button {
                    model.select(tool)
                } label: {
                    Image(systemName: tool.symbol)
                        .frame(width: 32, height: 28)
                        .background(model.selectedTool == tool ? Color.accentColor.opacity(0.25) : .clear)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .help(tool.label)
            }
            Spacer()
            Button("Undo") { model.onUndo?() }
            Button("Copy") { model.onCopy?() }
            Button("Save") { model.onSave?() }
        }
    }
}
