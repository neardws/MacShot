import AppKit
import SwiftUI
import OctoshotCore

struct QuickAccessActions {
    var onCopy: () -> Void
    var onSave: () -> Void
    var onAnnotate: () -> Void
    var onPin: () -> Void
    var onOCR: () -> Void
    var onAskAI: (() -> Void)?
    var onCopyMarkdown: (() -> Void)?
    var onCopyPath: (() -> Void)?
    var onClose: () -> Void
}

@MainActor
private final class QuickAccessEntry: Identifiable {
    let id = UUID()
    let image: NSImage
    let actions: QuickAccessActions
    let speculativeState: SpeculativeActionState

    init(image: NSImage, actions: QuickAccessActions) {
        self.image = image
        self.actions = actions
        self.speculativeState = SpeculativeActionState()
    }
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
        let entry = QuickAccessEntry(image: image, actions: actions)
        entries.insert(entry, at: 0)
        if entries.count > maxStackCount {
            let removed = entries.suffix(from: maxStackCount)
            removed.forEach { SpeculativeCapturePipeline.shared.cancel(entryID: $0.id) }
            entries.removeLast(entries.count - maxStackCount)
        }
        SpeculativeCapturePipeline.shared.start(entryID: entry.id, image: image, state: entry.speculativeState)
        rebuildPanel()
        scheduleAutoCloseIfNeeded()
    }

    func closePanel() {
        autoCloseTimer?.invalidate()
        autoCloseTimer = nil
        SpeculativeCapturePipeline.shared.cancelAll()
        entries.removeAll()
        panel?.orderOut(nil)
        panel = nil
    }

    private func removeEntry(id: UUID) {
        SpeculativeCapturePipeline.shared.cancel(entryID: id)
        entries.removeAll { $0.id == id }
        if entries.isEmpty {
            closePanel()
        } else {
            rebuildPanel()
        }
    }

    private func cancelSpeculative(for entry: QuickAccessEntry) {
        SpeculativeCapturePipeline.shared.cancel(entryID: entry.id)
        entry.speculativeState.phase = .hidden
    }

    private func rebuildPanel() {
        let root = QuickAccessStackView(
            entries: entries,
            maxThumbWidth: maxThumbWidth,
            maxThumbHeight: maxThumbHeight,
            onDismissEntry: { [weak self] id in self?.removeEntry(id: id) },
            onUserChoseAlternateAction: { [weak self] entry in
                self?.cancelSpeculative(for: entry)
            }
        )

        let hosting = NSHostingView(rootView: root)
        let fitting = hosting.fittingSize
        let size = NSSize(
            width: min(max(fitting.width, 160), maxThumbWidth + 48),
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
    let onUserChoseAlternateAction: (QuickAccessEntry) -> Void

    var body: some View {
        VStack(alignment: .trailing, spacing: 10) {
            ForEach(entries) { entry in
                QuickAccessCard(
                    entry: entry,
                    thumbSize: QuickAccessPanelController.aspectFitSize(
                        for: entry.image,
                        maxWidth: maxThumbWidth,
                        maxHeight: maxThumbHeight
                    ),
                    onClose: { onDismissEntry(entry.id) },
                    onAlternateAction: { onUserChoseAlternateAction(entry) }
                )
            }
        }
        .padding(12)
    }
}

private struct QuickAccessCard: View {
    @ObservedObject var speculativeState: SpeculativeActionState
    let entry: QuickAccessEntry
    let thumbSize: NSSize
    let onClose: () -> Void
    let onAlternateAction: () -> Void
    @State private var isHovering = false

    init(
        entry: QuickAccessEntry,
        thumbSize: NSSize,
        onClose: @escaping () -> Void,
        onAlternateAction: @escaping () -> Void
    ) {
        self.entry = entry
        self.speculativeState = entry.speculativeState
        self.thumbSize = thumbSize
        self.onClose = onClose
        self.onAlternateAction = onAlternateAction
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            SpeculativePrimaryButton(
                phase: speculativeState.phase,
                onApply: { applySpeculativeResult() }
            )

            ZStack(alignment: .bottom) {
                DraggableThumbnailView(image: entry.image, size: thumbSize)
                    .frame(width: thumbSize.width, height: thumbSize.height)
                    .background(Color.black.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: .black.opacity(0.35), radius: 10, y: 4)

                if isHovering {
                    HStack(spacing: 8) {
                        QuickAccessButton(symbol: "doc.on.doc", help: "Copy", action: wrapAlternate(entry.actions.onCopy))
                        QuickAccessButton(symbol: "square.and.arrow.down", help: "Save", action: wrapAlternate(entry.actions.onSave))
                        QuickAccessButton(symbol: "pencil.tip.crop.circle", help: "Annotate", action: wrapAlternate(entry.actions.onAnnotate))
                        QuickAccessButton(symbol: "pin.fill", help: "贴图 / Pin", action: wrapAlternate(entry.actions.onPin))
                        QuickAccessButton(
                            symbol: "text.viewfinder",
                            help: OctoshotL10n.ocrAction,
                            action: wrapAlternate(entry.actions.onOCR)
                        )
                        if let onAskAI = entry.actions.onAskAI {
                            QuickAccessButton(symbol: "brain", help: "Ask AI", action: wrapAlternate(onAskAI))
                        }
                        if let onCopyMarkdown = entry.actions.onCopyMarkdown {
                            QuickAccessButton(symbol: "doc.richtext", help: "Copy Markdown", action: wrapAlternate(onCopyMarkdown))
                        }
                        if let onCopyPath = entry.actions.onCopyPath {
                            QuickAccessButton(symbol: "link", help: "Copy file path", action: wrapAlternate(onCopyPath))
                        }
                        QuickAccessButton(symbol: "xmark", help: "Close", action: onClose)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.bottom, 8)
                }
            }
        }
        .onHover { isHovering = $0 }
        .animation(.easeInOut(duration: 0.15), value: isHovering)
    }

    private func wrapAlternate(_ action: @escaping () -> Void) -> () -> Void {
        {
            onAlternateAction()
            action()
        }
    }

    private func applySpeculativeResult() {
        guard case .ready(_, let result) = speculativeState.phase else { return }
        switch result {
        case .latex(let text), .tableMarkdown(let text), .codeText(let text):
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
        case .redactedImage(let image):
            ImageFormats.copyToPasteboard(image)
        }
        onAlternateAction()
        speculativeState.phase = .hidden
    }
}

private struct SpeculativePrimaryButton: View {
    let phase: SpeculativeActionState.Phase
    let onApply: () -> Void

    var body: some View {
        switch phase {
        case .hidden:
            EmptyView()
        case .classifying:
            pill(label: "Analyzing…", systemImage: "sparkles", progress: true, enabled: false)
        case .running(let kind, let detail):
            pill(label: detail, systemImage: kind.systemImage, progress: true, enabled: false)
        case .ready(let kind, _):
            Button(action: onApply) {
                pillContent(label: "Apply \(kind.displayName)", systemImage: kind.systemImage, progress: false)
            }
            .buttonStyle(.plain)
        case .suggestionOnly(let kind, let reason):
            pill(label: "\(kind.displayName) — \(reason)", systemImage: kind.systemImage, progress: false, enabled: false)
                .opacity(0.75)
        case .failed(let message):
            pill(label: message, systemImage: "exclamationmark.triangle", progress: false, enabled: false)
                .foregroundStyle(.orange)
        }
    }

    @ViewBuilder
    private func pill(label: String, systemImage: String, progress: Bool, enabled: Bool) -> some View {
        HStack(spacing: 8) {
            pillContent(label: label, systemImage: systemImage, progress: progress)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThickMaterial, in: Capsule())
        .opacity(enabled ? 1 : 0.95)
    }

    private func pillContent(label: String, systemImage: String, progress: Bool) -> some View {
        HStack(spacing: 8) {
            if progress {
                ProgressView()
                    .controlSize(.small)
            } else {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .semibold))
            }
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(1)
        }
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
