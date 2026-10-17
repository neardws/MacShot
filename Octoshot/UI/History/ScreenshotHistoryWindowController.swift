import AppKit
import ImageIO
import SwiftUI
import OctoshotCore

@MainActor
final class ScreenshotHistoryWindowController {
    static let shared = ScreenshotHistoryWindowController()
    private var window: NSWindow?

    func show() {
        let view = ScreenshotHistoryView()
        let hosting = NSHostingController(rootView: view)
        if window == nil {
            let window = NSWindow(contentViewController: hosting)
            window.title = OctoshotL10n.historyWindowTitle
            window.setContentSize(NSSize(width: 880, height: 560))
            window.minSize = NSSize(width: 640, height: 400)
            window.center()
            self.window = window
        } else {
            window?.contentViewController = hosting
            window?.title = OctoshotL10n.historyWindowTitle
        }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct ScreenshotHistoryView: View {
    @State private var entries: [ScreenshotHistoryEntry] = []
    @State private var selection: URL?
    @State private var previewImage: NSImage?
    @State private var loadToken = UUID()

    private let thumbSize: CGFloat = 96
    private let columns = [GridItem(.adaptive(minimum: 108), spacing: 8)]

    var body: some View {
        NavigationSplitView {
            Group {
                if entries.isEmpty {
                    ContentUnavailableView(
                        OctoshotL10n.historyEmptyLibrary,
                        systemImage: "photo.on.rectangle.angled"
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(entries) { entry in
                                thumbnailCell(entry)
                            }
                        }
                        .padding(8)
                    }
                }
            }
            .navigationTitle(OctoshotL10n.historyWindowTitle)
            .toolbar {
                ToolbarItemGroup {
                    Button(OctoshotL10n.historyRefresh) { reload() }
                    Button(OctoshotL10n.historyOpenFolder) {
                        NSWorkspace.shared.open(AppSettings.shared.saveDirectory)
                    }
                }
            }
        } detail: {
            detailPane
        }
        .onAppear { reload() }
        .onReceive(NotificationCenter.default.publisher(for: .octoshotRecentCapturesDidChange)) { _ in
            reload()
        }
        .onChange(of: selection) { _, newValue in
            loadPreview(for: newValue)
        }
    }

    @ViewBuilder
    private func thumbnailCell(_ entry: ScreenshotHistoryEntry) -> some View {
        let isSelected = selection == entry.url
        HistoryThumbnailView(url: entry.url, size: thumbSize)
            .frame(width: thumbSize, height: thumbSize)
            .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: isSelected ? 2 : 1)
            )
            .help(entry.filename)
            .onTapGesture {
                selection = entry.url
            }
            .contextMenu {
                historyActions(for: entry.url)
            }
    }

    @ViewBuilder
    private var detailPane: some View {
        if let url = selection, let image = previewImage {
            VStack(spacing: 0) {
                HStack {
                    Text(url.lastPathComponent)
                        .font(.headline)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    actionButtons(for: url, image: image)
                }
                .padding()

                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
            }
        } else {
            ContentUnavailableView(
                OctoshotL10n.historyEmptySelection,
                systemImage: "photo"
            )
        }
    }

    @ViewBuilder
    private func actionButtons(for url: URL, image: NSImage) -> some View {
        HStack {
            Button(OctoshotL10n.ocrCopy) { ScreenshotHistoryStore.copyToClipboard(url: url) }
            Button(OctoshotL10n.historyPinAction) { PinnedScreenshotManager.shared.pin(image: image) }
            Button(OctoshotL10n.ocrAction) { FeatureCoordinator.shared.showOCR(with: image) }
            Button(OctoshotL10n.historyRevealInFinder) { ScreenshotHistoryStore.revealInFinder(url: url) }
            Button(OctoshotL10n.historyDelete, role: .destructive) { confirmDelete(url: url) }
        }
    }

    @ViewBuilder
    private func historyActions(for url: URL) -> some View {
        Button(OctoshotL10n.ocrCopy) { ScreenshotHistoryStore.copyToClipboard(url: url) }
        if let image = NSImage(contentsOf: url) {
            Button(OctoshotL10n.historyPinAction) { PinnedScreenshotManager.shared.pin(image: image) }
            Button(OctoshotL10n.ocrAction) { FeatureCoordinator.shared.showOCR(with: image) }
        }
        Button(OctoshotL10n.historyRevealInFinder) { ScreenshotHistoryStore.revealInFinder(url: url) }
        Divider()
        Button(OctoshotL10n.historyDelete, role: .destructive) { confirmDelete(url: url) }
    }

    private func reload() {
        entries = ScreenshotHistoryStore.loadEntries()
        if let selection, !entries.contains(where: { $0.url == selection }) {
            self.selection = entries.first?.url
        } else if selection == nil {
            selection = entries.first?.url
        }
        loadPreview(for: selection)
    }

    private func loadPreview(for url: URL?) {
        let token = UUID()
        loadToken = token
        previewImage = nil
        guard let url else { return }
        Task.detached(priority: .userInitiated) {
            let image = NSImage(contentsOf: url)
            await MainActor.run {
                guard loadToken == token, selection == url else { return }
                previewImage = image
            }
        }
    }

    private func confirmDelete(url: URL) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = OctoshotL10n.historyDeleteConfirmTitle
        alert.informativeText = OctoshotL10n.historyDeleteConfirmMessage(url.lastPathComponent)
        alert.addButton(withTitle: OctoshotL10n.historyDelete)
        alert.addButton(withTitle: OctoshotL10n.historyCancel)
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        do {
            try ScreenshotHistoryStore.delete(url: url)
            if selection == url {
                selection = nil
                previewImage = nil
            }
            reload()
        } catch {
            let err = NSAlert()
            err.messageText = OctoshotL10n.historyDeleteFailed
            err.informativeText = error.localizedDescription
            err.runModal()
        }
    }
}

private struct HistoryThumbnailView: View {
    let url: URL
    let size: CGFloat
    @State private var image: NSImage?

    var body: some View {
        Group {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .clipped()
        .task(id: url) {
            image = await loadThumbnail()
        }
    }

    private func loadThumbnail() async -> NSImage? {
        await Task.detached(priority: .utility) {
            guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
                return NSImage(contentsOf: url)
            }
            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceThumbnailMaxPixelSize: size * 2,
                kCGImageSourceCreateThumbnailWithTransform: true,
            ]
            guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
                return NSImage(contentsOf: url)
            }
            return NSImage(cgImage: cgImage, size: NSSize(width: size, height: size))
        }.value
    }
}
