import AppKit
import SwiftUI

struct QuickAccessActions {
    var onCopy: () -> Void
    var onSave: () -> Void
    var onAnnotate: () -> Void
    var onClose: () -> Void
}

@MainActor
final class QuickAccessPanelController: NSObject {
    private var panel: NSPanel?
    private var image: NSImage?
    private var actions: QuickAccessActions?
    private var autoCloseTimer: Timer?

    func show(image: NSImage, actions: QuickAccessActions) {
        closePanel()
        self.image = image
        self.actions = actions

        let maxThumb: CGFloat = 160
        let aspect = image.size.width / max(image.size.height, 1)
        let thumbWidth = min(maxThumb, image.size.width)
        let thumbHeight = thumbWidth / aspect

        let root = QuickAccessRootView(
            image: image,
            thumbSize: NSSize(width: thumbWidth, height: thumbHeight),
            actions: actions
        )
        let hosting = NSHostingView(rootView: root)

        let panelWidth = thumbWidth + 24
        let panelHeight = thumbHeight + 56
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: panelHeight),
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
        panel.contentView = hosting
        panel.contentView?.wantsLayer = true
        panel.contentView?.layer?.cornerRadius = 12

        position(panel: panel, size: NSSize(width: panelWidth, height: panelHeight))
        panel.orderFrontRegardless()
        self.panel = panel
        scheduleAutoCloseIfNeeded()
    }

    func closePanel() {
        autoCloseTimer?.invalidate()
        autoCloseTimer = nil
        panel?.orderOut(nil)
        panel = nil
        image = nil
        actions = nil
    }

    private func position(panel: NSPanel, size: NSSize) {
        guard let screen = NSScreen.main else { return }
        let margin: CGFloat = 16
        let frame = screen.visibleFrame
        let corner = AppSettings.shared.quickAccessCorner
        let origin: NSPoint
        switch corner {
        case .topLeft:
            origin = NSPoint(x: frame.minX + margin, y: frame.maxY - size.height - margin)
        case .topRight:
            origin = NSPoint(x: frame.maxX - size.width - margin, y: frame.maxY - size.height - margin)
        case .bottomLeft:
            origin = NSPoint(x: frame.minX + margin, y: frame.minY + margin)
        case .bottomRight:
            origin = NSPoint(x: frame.maxX - size.width - margin, y: frame.minY + margin)
        }
        panel.setFrame(NSRect(origin: origin, size: size), display: true)
    }

    private func scheduleAutoCloseIfNeeded() {
        autoCloseTimer?.invalidate()
        let delay = AppSettings.shared.quickAccessAutoCloseSeconds
        guard delay > 0 else { return }
        autoCloseTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.closePanel() }
        }
    }
}

private struct QuickAccessRootView: View {
    let image: NSImage
    let thumbSize: NSSize
    let actions: QuickAccessActions

    var body: some View {
        VStack(spacing: 8) {
            DraggableThumbnailView(image: image, size: thumbSize)
                .frame(width: thumbSize.width, height: thumbSize.height)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            HStack(spacing: 10) {
                QuickAccessButton(symbol: "doc.on.doc", help: "Copy") { actions.onCopy() }
                QuickAccessButton(symbol: "square.and.arrow.down", help: "Save") { actions.onSave() }
                QuickAccessButton(symbol: "pencil.tip.crop.circle", help: "Annotate") { actions.onAnnotate() }
                QuickAccessButton(symbol: "xmark", help: "Close") { actions.onClose() }
            }
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct QuickAccessButton: View {
    let symbol: String
    let help: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .frame(width: 28, height: 28)
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
        view.frame = NSRect(origin: .zero, size: size)
        return view
    }

    func updateNSView(_ nsView: DraggableImageView, context: Context) {
        nsView.image = image
    }
}

final class DraggableImageView: NSImageView {
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
