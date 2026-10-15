import AppKit
import SwiftUI
import OctoshotCore

struct QuickAccessActions {
    var onCopy: () -> Void
    var onSave: () -> Void
    var onAnnotate: () -> Void
    var onAskAI: (() -> Void)?
    var onCopyMarkdown: (() -> Void)?
    var onCopyPath: (() -> Void)?
    var onClose: () -> Void
}

private struct QuickAccessEntry: Identifiable {
    let id = UUID()
    let image: NSImage
    let actions: QuickAccessActions
}

@MainActor
final class QuickAccessPanelController: NSObject {
    private var panel: NSPanel?
    private var entries: [QuickAccessEntry] = []
    private var autoCloseTimer: Timer?

    private let maxThumbWidth: CGFloat = 240
    private let maxThumbHeight: CGFloat = 180
    private let maxStackCount = 6

    func show(image: NSImage, actions: QuickAccessActions) {
        entries.insert(QuickAccessEntry(image: image, actions: actions), at: 0)
        if entries.count > maxStackCount {
            entries.removeLast(entries.count - maxStackCount)
        }
        rebuildPanel()
        scheduleAutoCloseIfNeeded()
    }

    func closePanel() {
        autoCloseTimer?.invalidate()
        autoCloseTimer = nil
        entries.removeAll()
        panel?.orderOut(nil)
        panel = nil
    }

    private func removeEntry(id: UUID) {
        entries.removeAll { $0.id == id }
        if entries.isEmpty {
            closePanel()
        } else {
            rebuildPanel()
        }
    }

    private func rebuildPanel() {
        let root = QuickAccessStackView(
            entries: entries,
            maxThumbWidth: maxThumbWidth,
            maxThumbHeight: maxThumbHeight,
            onDismissEntry: { [weak self] id in self?.removeEntry(id: id) }
        )

        let hosting = NSHostingView(rootView: root)
        let fitting = hosting.fittingSize
        let size = NSSize(
            width: min(max(fitting.width, 120), maxThumbWidth + 32),
            height: fitting.height
        )

        if panel == nil {
            let panel = NSPanel(
                contentRect: NSRect(origin: .zero, size: size),
                styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
                backing: .buffered,
                defer: false
            )
            panel.isFloatingPanel = true
            panel.level = .floating
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.backgroundColor = .clear
            panel.isOpaque = false
            panel.hasShadow = true
            self.panel = panel
        }

        panel?.contentView = hosting
        panel?.setContentSize(size)
        if let panel {
            position(panel: panel, size: size)
            panel.orderFrontRegardless()
        }
    }

    private func position(panel: NSPanel, size: NSSize) {
        let screen = screenForCornerPreference()
        let margin: CGFloat = 16
        var frame = screen.visibleFrame
        frame = frame.insetBy(dx: margin, dy: margin)

        let corner = AppSettings.shared.quickAccessCorner
        var origin = NSPoint.zero
        switch corner {
        case .topLeft:
            origin = NSPoint(x: frame.minX, y: frame.maxY - size.height)
        case .topRight:
            origin = NSPoint(x: frame.maxX - size.width, y: frame.maxY - size.height)
        case .bottomLeft:
            origin = NSPoint(x: frame.minX, y: frame.minY)
        case .bottomRight:
            origin = NSPoint(x: frame.maxX - size.width, y: frame.minY)
        }

        origin.x = min(max(origin.x, frame.minX), frame.maxX - size.width)
        origin.y = min(max(origin.y, frame.minY), frame.maxY - size.height)

        panel.setFrame(NSRect(origin: origin, size: size), display: true)
    }

    private func screenForCornerPreference() -> NSScreen {
        NSScreen.main ?? NSScreen.screens.first ?? NSScreen.screens[0]
    }

    private func scheduleAutoCloseIfNeeded() {
        autoCloseTimer?.invalidate()
        let delay = AppSettings.shared.quickAccessAutoCloseSeconds
        guard delay > 0 else { return }
        autoCloseTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.closePanel() }
        }
    }

    static func aspectFitSize(for image: NSImage, maxWidth: CGFloat, maxHeight: CGFloat) -> NSSize {
        let w = max(image.size.width, 1)
        let h = max(image.size.height, 1)
        let scale = min(maxWidth / w, maxHeight / h)
        return NSSize(width: floor(w * scale), height: floor(h * scale))
    }
}

private struct QuickAccessStackView: View {
    let entries: [QuickAccessEntry]
    let maxThumbWidth: CGFloat
    let maxThumbHeight: CGFloat
    let onDismissEntry: (UUID) -> Void

    var body: some View {
        VStack(alignment: .trailing, spacing: 10) {
            ForEach(entries) { entry in
                QuickAccessCard(
                    image: entry.image,
                    thumbSize: QuickAccessPanelController.aspectFitSize(
                        for: entry.image,
                        maxWidth: maxThumbWidth,
                        maxHeight: maxThumbHeight
                    ),
                    actions: entry.actions,
                    onClose: { onDismissEntry(entry.id) }
                )
            }
        }
        .padding(12)
    }
}

private struct QuickAccessCard: View {
    let image: NSImage
    let thumbSize: NSSize
    let actions: QuickAccessActions
    let onClose: () -> Void
    @State private var isHovering = false

    var body: some View {
        ZStack(alignment: .bottom) {
            DraggableThumbnailView(image: image, size: thumbSize)
                .frame(width: thumbSize.width, height: thumbSize.height)
                .background(Color.black.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(color: .black.opacity(0.35), radius: 10, y: 4)

            if isHovering {
                HStack(spacing: 8) {
                    QuickAccessButton(symbol: "doc.on.doc", help: "Copy", action: actions.onCopy)
                    QuickAccessButton(symbol: "square.and.arrow.down", help: "Save", action: actions.onSave)
                    QuickAccessButton(symbol: "pencil.tip.crop.circle", help: "Annotate", action: actions.onAnnotate)
                    if let onAskAI = actions.onAskAI {
                        QuickAccessButton(symbol: "brain", help: "Ask AI", action: onAskAI)
                    }
                    if let onCopyMarkdown = actions.onCopyMarkdown {
                        QuickAccessButton(symbol: "doc.richtext", help: "Copy Markdown", action: onCopyMarkdown)
                    }
                    if let onCopyPath = actions.onCopyPath {
                        QuickAccessButton(symbol: "link", help: "Copy file path", action: onCopyPath)
                    }
                    QuickAccessButton(symbol: "xmark", help: "Close", action: onClose)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(.bottom, 8)
            }
        }
        .onHover { isHovering = $0 }
        .animation(.easeInOut(duration: 0.15), value: isHovering)
    }
}

private struct QuickAccessButton: View {
    let symbol: String
    let help: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .frame(width: 26, height: 26)
        }
        .buttonStyle(.plain)
        .help(help)
    }
}

private struct DraggableThumbnailView: NSViewRepresentable {
    let image: NSImage
    let size: NSSize

    func makeNSView(context: Context) -> DraggableImageView {
        let view = DraggableImageView()
        view.image = image
        view.imageScaling = .scaleProportionallyUpOrDown
        return view
    }

    func updateNSView(_ nsView: DraggableImageView, context: Context) {
        nsView.image = image
    }
}

final class DraggableImageView: NSImageView {
    override var isFlipped: Bool { true }

    override func mouseDown(with event: NSEvent) {
        guard let image else { return }
        let item = NSPasteboardItem()
        if let data = ImageFormats.pngData(from: image) {
            item.setData(data, forType: .png)
        }
        let dragging = NSDraggingItem(pasteboardWriter: item)
        dragging.setDraggingFrame(bounds, contents: image)
        beginDraggingSession(with: [dragging], event: event, source: self)
    }
}

extension DraggableImageView: NSDraggingSource {
    func draggingSession(
        _ session: NSDraggingSession,
        sourceOperationMaskFor context: NSDraggingContext
    ) -> NSDragOperation {
        .copy
    }
}
