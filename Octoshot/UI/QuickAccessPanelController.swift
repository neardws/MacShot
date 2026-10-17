import AppKit
import SwiftUI
import OctoshotCore

private struct QuickAccessPanelSizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

private extension QuickAccessStackGeometry.CollapsedStackAnchor {
    var swiftUIAlignment: Alignment {
        switch self {
        case .bottomLeading:
            return .bottomLeading
        case .bottomTrailing:
            return .bottomTrailing
        case .topLeading:
            return .topLeading
        case .topTrailing:
            return .topTrailing
        }
    }
}

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
    private var lastCaptureAnchor: CGPoint?
    private var placementObserver: NSObjectProtocol?

    private let maxThumbWidth: CGFloat = 240
    private let maxThumbHeight: CGFloat = 180
    private let maxStackCount = 6

    override init() {
        super.init()
        placementObserver = NotificationCenter.default.addObserver(
            forName: .octoshotQuickAccessPlacementDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.repositionIfNeeded() }
        }
    }

    deinit {
        if let placementObserver {
            NotificationCenter.default.removeObserver(placementObserver)
        }
    }

    func show(image: NSImage, actions: QuickAccessActions, captureAnchor: CGPoint?) {
        lastCaptureAnchor = captureAnchor
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

    private func repositionIfNeeded() {
        guard let panel else { return }
        position(panel: panel, size: panel.frame.size)
    }

    private func rebuildPanel() {
        let settings = AppSettings.shared
        let root = QuickAccessStackView(
            entries: entries,
            placement: settings.quickAccessPlacement,
            stackCapturesEnabled: settings.quickAccessStackCaptures,
            maxThumbWidth: maxThumbWidth,
            maxThumbHeight: maxThumbHeight,
            onDismissEntry: { [weak self] id in self?.removeEntry(id: id) },
            onDismissAll: { [weak self] in self?.closePanel() },
            onUserChoseAlternateAction: { [weak self] entry in
                self?.cancelSpeculative(for: entry)
            },
            onContentSizeChange: { [weak self] size in
                self?.applyPanelContentSize(size)
            }
        )

        let hosting = NSHostingView(rootView: root)
        let fitting = hosting.fittingSize
        let size = Self.clampedPanelSize(from: fitting, maxThumbWidth: maxThumbWidth)

        if panel == nil {
            let panel = NSPanel(
                contentRect: NSRect(origin: .zero, size: size),
                styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
                backing: .buffered,
                defer: false
            )
            FullScreenOverlaySupport.configureFloatingOverlayPanel(panel)
            panel.backgroundColor = .clear
            panel.isOpaque = false
            panel.hasShadow = false
            self.panel = panel
        }

        panel?.contentView = hosting
        panel?.setContentSize(size)
        if let panel {
            position(panel: panel, size: size)
            panel.orderFrontRegardless()
        }
    }

    private func applyPanelContentSize(_ contentSize: CGSize) {
        guard let panel else { return }
        let size = Self.clampedPanelSize(from: contentSize, maxThumbWidth: maxThumbWidth)
        let current = panel.frame.size
        guard abs(current.width - size.width) > 0.5 || abs(current.height - size.height) > 0.5 else { return }
        panel.setContentSize(size)
        position(panel: panel, size: size)
    }

    private static func clampedPanelSize(from fitting: CGSize, maxThumbWidth: CGFloat) -> NSSize {
        NSSize(
            width: min(max(fitting.width, 160), maxThumbWidth + 56),
            height: fitting.height
        )
    }

    private func position(panel: NSPanel, size: NSSize) {
        let screen = screenForPanel()
        let margin: CGFloat = 16
        let origin = QuickAccessPanelGeometry.panelOrigin(
            placement: AppSettings.shared.quickAccessPlacement,
            visibleFrame: screen.visibleFrame,
            panelSize: CGSize(width: size.width, height: size.height),
            margin: margin
        )
        panel.setFrame(NSRect(origin: origin, size: size), display: true)
    }

    private func screenForPanel() -> NSScreen {
        let screens = NSScreen.screens.map {
            QuickAccessScreenInfo(
                displayID: $0.displayID,
                frame: $0.frame,
                visibleFrame: $0.visibleFrame
            )
        }
        let mouse = NSEvent.mouseLocation
        if let info = QuickAccessScreenSelection.selectScreen(
            screens: screens,
            capturePoint: lastCaptureAnchor,
            mousePoint: mouse
        ),
           let match = NSScreen.screens.first(where: { $0.displayID == info.displayID }) {
            return match
        }
        return NSScreen.main ?? NSScreen.screens.first ?? NSScreen.screens[0]
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
    let placement: QuickAccessPlacement
    let stackCapturesEnabled: Bool
    let maxThumbWidth: CGFloat
    let maxThumbHeight: CGFloat
    let onDismissEntry: (UUID) -> Void
    let onDismissAll: () -> Void
    let onUserChoseAlternateAction: (QuickAccessEntry) -> Void
    let onContentSizeChange: (CGSize) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isStackExpanded = false
    @State private var isStackHovering = false
    @State private var panelAppeared = false

    private var useCollapsedStack: Bool {
        stackCapturesEnabled && entries.count > 1 && !isStackExpanded
    }

    var body: some View {
        VStack(alignment: horizontalAlignment, spacing: 10) {
            if entries.count > 1 {
                stackHeader
            }

            if useCollapsedStack {
                collapsedStack
                    .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: collapseTransitionAnchor)))
            } else {
                expandedList
                    .transition(.opacity)
            }
        }
        .animation(reduceMotion ? nil : .spring(response: 0.38, dampingFraction: 0.82), value: useCollapsedStack)
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.12), radius: 1, y: 1)
                .shadow(color: .black.opacity(0.2), radius: 18, y: 8)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        }
        .scaleEffect(panelAppeared ? 1 : 0.94)
        .opacity(panelAppeared ? 1 : 0)
        .onAppear {
            guard !reduceMotion else {
                panelAppeared = true
                return
            }
            withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
                panelAppeared = true
            }
        }
        .onChange(of: entries.count) { _, newCount in
            if newCount <= 1 {
                isStackExpanded = false
            }
        }
        .background {
            GeometryReader { proxy in
                Color.clear.preference(key: QuickAccessPanelSizeKey.self, value: proxy.size)
            }
        }
        .onPreferenceChange(QuickAccessPanelSizeKey.self) { size in
            guard size.width > 0, size.height > 0 else { return }
            onContentSizeChange(size)
        }
    }

    private var horizontalAlignment: HorizontalAlignment {
        switch placement {
        case .bottomLeft, .leftSidebar:
            return .leading
        case .bottomRight, .rightSidebar:
            return .trailing
        }
    }

    private var collapseTransitionAnchor: UnitPoint {
        switch placement {
        case .bottomLeft:
            return .bottomLeading
        case .bottomRight:
            return .bottomTrailing
        case .leftSidebar:
            return .topLeading
        case .rightSidebar:
            return .topTrailing
        }
    }

    @ViewBuilder
    private var stackHeader: some View {
        HStack {
            if placement == .bottomRight || placement == .rightSidebar {
                Spacer(minLength: 0)
            }
            if isStackExpanded || isStackHovering || !useCollapsedStack {
                Button(action: onDismissAll) {
                    Label(OctoshotL10n.quickAccessCloseAll, systemImage: "xmark.circle.fill")
                        .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help(OctoshotL10n.quickAccessCloseAll)
            }
            if placement == .bottomLeft || placement == .leftSidebar {
                Spacer(minLength: 0)
            }
        }
    }

    private var expandedList: some View {
        VStack(alignment: horizontalAlignment, spacing: 10) {
            ForEach(entries) { entry in
                QuickAccessCard(
                    entry: entry,
                    placement: placement,
                    thumbSize: QuickAccessPanelController.aspectFitSize(
                        for: entry.image,
                        maxWidth: maxThumbWidth,
                        maxHeight: maxThumbHeight
                    ),
                    onClose: { onDismissEntry(entry.id) },
                    onAlternateAction: { onUserChoseAlternateAction(entry) },
                    onDragSucceeded: { onDismissEntry(entry.id) }
                )
                .transition(
                    .asymmetric(
                        insertion: .scale(scale: 0.9).combined(with: .opacity),
                        removal: .opacity
                    )
                )
            }
        }
        .animation(reduceMotion ? nil : .spring(response: 0.38, dampingFraction: 0.82), value: entries.map(\.id))
    }

    private var collapsedStack: some View {
        let frontThumb = QuickAccessPanelController.aspectFitSize(
            for: entries[0].image,
            maxWidth: maxThumbWidth,
            maxHeight: maxThumbHeight
        )
        let frontSize = CGSize(width: frontThumb.width, height: frontThumb.height)
        let stackSize = QuickAccessStackGeometry.collapsedStackContentSize(
            frontCardSize: frontSize,
            total: entries.count,
            placement: placement
        )
        let frameAlignment = QuickAccessStackGeometry.collapsedStackAnchor(placement: placement).swiftUIAlignment

        return ZStack(alignment: .topLeading) {
            ForEach(Array(entries.enumerated().reversed()), id: \.element.id) { index, entry in
                if index < QuickAccessStackGeometry.maxCollapsedLayers {
                    let thumbSize = QuickAccessPanelController.aspectFitSize(
                        for: entry.image,
                        maxWidth: maxThumbWidth,
                        maxHeight: maxThumbHeight
                    )
                    QuickAccessCard(
                        entry: entry,
                        placement: placement,
                        thumbSize: thumbSize,
                        onClose: { onDismissEntry(entry.id) },
                        onAlternateAction: { onUserChoseAlternateAction(entry) },
                        onDragSucceeded: index == 0 ? { onDismissEntry(entry.id) } : nil,
                        showsActionsOnHover: index == 0
                    )
                    .overlay(alignment: stackBadgeAlignment) {
                        if index == 0, entries.count > 1 {
                            stackCountBadge
                        }
                    }
                    .offset(
                        QuickAccessStackGeometry.collapsedOffset(
                            index: index,
                            total: entries.count,
                            placement: placement
                        )
                    )
                    .zIndex(QuickAccessStackGeometry.collapsedZIndex(index: index, total: entries.count))
                    .allowsHitTesting(index == 0)
                }
            }
        }
        .frame(width: stackSize.width, height: stackSize.height, alignment: frameAlignment)
        .animation(reduceMotion ? nil : .spring(response: 0.38, dampingFraction: 0.82), value: entries.count)
        .contentShape(Rectangle())
        .onHover { hovering in
            isStackHovering = hovering
            if hovering, stackCapturesEnabled, entries.count > 1 {
                expandStackIfNeeded()
            }
        }
        .onTapGesture {
            expandStackIfNeeded()
        }
    }

    private var stackCountBadge: some View {
        Text("\(entries.count)")
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Capsule().fill(Color.accentColor))
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.35), lineWidth: 1))
            .padding(6)
            .allowsHitTesting(false)
    }

    private var stackBadgeAlignment: Alignment {
        switch placement {
        case .bottomLeft, .leftSidebar:
            return .topLeading
        case .bottomRight, .rightSidebar:
            return .topTrailing
        }
    }

    private func expandStackIfNeeded() {
        guard !isStackExpanded else { return }
        if reduceMotion {
            isStackExpanded = true
        } else {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isStackExpanded = true
            }
        }
    }
}

private struct QuickAccessCard: View {
    @ObservedObject var speculativeState: SpeculativeActionState
    let entry: QuickAccessEntry
    let placement: QuickAccessPlacement
    let thumbSize: NSSize
    let onClose: () -> Void
    let onAlternateAction: () -> Void
    var onDragSucceeded: (() -> Void)?
    var showsActionsOnHover: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovering = false

    init(
        entry: QuickAccessEntry,
        placement: QuickAccessPlacement,
        thumbSize: NSSize,
        onClose: @escaping () -> Void,
        onAlternateAction: @escaping () -> Void,
        onDragSucceeded: (() -> Void)? = nil,
        showsActionsOnHover: Bool = true
    ) {
        self.entry = entry
        self.placement = placement
        self.speculativeState = entry.speculativeState
        self.thumbSize = thumbSize
        self.onClose = onClose
        self.onAlternateAction = onAlternateAction
        self.onDragSucceeded = onDragSucceeded
        self.showsActionsOnHover = showsActionsOnHover
    }

    var body: some View {
        VStack(alignment: cardAlignment, spacing: 8) {
            SpeculativePrimaryButton(
                phase: speculativeState.phase,
                onApply: { applySpeculativeResult() }
            )

            ZStack(alignment: .bottom) {
                QuickAccessThumbnailChrome(isHovering: showsActionsOnHover && isHovering, reduceMotion: reduceMotion) {
                    DraggableThumbnailView(
                        image: entry.image,
                        size: thumbSize,
                        onDragEnded: { operation in
                            if QuickAccessDragOutcome.fromEndedDragOperation(operation) == .removeFromStack {
                                onDragSucceeded?()
                            }
                        }
                    )
                        .frame(width: thumbSize.width, height: thumbSize.height)
                }

                if showsActionsOnHover, isHovering {
                    HStack(spacing: 6) {
                        QuickAccessButton(
                            symbol: "doc.on.clipboard",
                            label: OctoshotL10n.quickAccessCopy,
                            action: wrapAlternate(entry.actions.onCopy)
                        )
                        QuickAccessButton(
                            symbol: "square.and.arrow.down.fill",
                            label: OctoshotL10n.quickAccessSave,
                            action: wrapAlternate(entry.actions.onSave)
                        )
                        QuickAccessButton(
                            symbol: "pencil.and.outline",
                            label: OctoshotL10n.quickAccessAnnotate,
                            action: wrapAlternate(entry.actions.onAnnotate)
                        )
                        QuickAccessButton(
                            symbol: "pin.circle.fill",
                            label: OctoshotL10n.quickAccessPin,
                            action: wrapAlternate(entry.actions.onPin)
                        )
                        QuickAccessButton(
                            symbol: "text.viewfinder",
                            label: OctoshotL10n.ocrAction,
                            action: wrapAlternate(entry.actions.onOCR)
                        )
                        if let onAskAI = entry.actions.onAskAI {
                            QuickAccessButton(
                                symbol: "sparkles",
                                label: OctoshotL10n.quickAccessAskAI,
                                action: wrapAlternate(onAskAI)
                            )
                        }
                        if let onCopyMarkdown = entry.actions.onCopyMarkdown {
                            QuickAccessButton(
                                symbol: "curlybraces.square",
                                label: OctoshotL10n.quickAccessCopyMarkdown,
                                action: wrapAlternate(onCopyMarkdown)
                            )
                        }
                        if let onCopyPath = entry.actions.onCopyPath {
                            QuickAccessButton(
                                symbol: "link.circle",
                                label: OctoshotL10n.quickAccessCopyPath,
                                action: wrapAlternate(onCopyPath)
                            )
                        }
                        QuickAccessButton(
                            symbol: "xmark.circle.fill",
                            label: OctoshotL10n.quickAccessClose,
                            action: onClose
                        )
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onHover { isHovering = showsActionsOnHover && $0 }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.18), value: isHovering)
    }

    private var cardAlignment: HorizontalAlignment {
        switch placement {
        case .bottomLeft, .leftSidebar:
            return .leading
        case .bottomRight, .rightSidebar:
            return .trailing
        }
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

private struct QuickAccessThumbnailChrome<Content: View>: View {
    let isHovering: Bool
    let reduceMotion: Bool
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .background(Color.black.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.42), Color.white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: .black.opacity(0.16), radius: 2, y: 1)
            .shadow(color: .black.opacity(0.28), radius: 14, y: 6)
            .rotation3DEffect(
                .degrees(reduceMotion || !isHovering ? 0 : 5),
                axis: (x: -0.35, y: 1, z: 0),
                perspective: 0.55
            )
            .scaleEffect(reduceMotion || !isHovering ? 1 : 1.025)
            .animation(reduceMotion ? nil : .spring(response: 0.32, dampingFraction: 0.74), value: isHovering)
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
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 22, height: 18)
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(minWidth: 40)
            .padding(.horizontal, 2)
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
        .help(label)
        .accessibilityLabel(label)
    }
}

private struct DraggableThumbnailView: NSViewRepresentable {
    let image: NSImage
    let size: NSSize
    var onDragEnded: (UInt) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onDragEnded: onDragEnded)
    }

    func makeNSView(context: Context) -> DraggableImageView {
        let view = DraggableImageView()
        view.image = image
        view.imageScaling = .scaleProportionallyUpOrDown
        view.onDragEnded = { context.coordinator.reportDragEnded(operation: $0) }
        return view
    }

    func updateNSView(_ nsView: DraggableImageView, context: Context) {
        nsView.image = image
        nsView.onDragEnded = { context.coordinator.reportDragEnded(operation: $0) }
        context.coordinator.onDragEnded = onDragEnded
    }

    final class Coordinator {
        var onDragEnded: (UInt) -> Void

        init(onDragEnded: @escaping (UInt) -> Void) {
            self.onDragEnded = onDragEnded
        }

        func reportDragEnded(operation: UInt) {
            onDragEnded(operation)
        }
    }
}

final class DraggableImageView: NSImageView {
    var onDragEnded: ((UInt) -> Void)?

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

    func draggingSession(
        _ session: NSDraggingSession,
        endedAt screenPoint: NSPoint,
        operation: NSDragOperation
    ) {
        onDragEnded?(operation.rawValue)
    }
}

private extension NSScreen {
    var displayID: CGDirectDisplayID {
        guard let number = deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
            return 0
        }
        return CGDirectDisplayID(number.uint32Value)
    }
}
