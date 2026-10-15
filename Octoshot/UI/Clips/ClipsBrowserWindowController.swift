import AppKit
import SwiftUI
import OctoshotCore

@MainActor
final class ClipsBrowserWindowController {
    static let shared = ClipsBrowserWindowController()
    private var window: NSWindow?

    func show() {
        let view = ClipsBrowserView()
        let hosting = NSHostingController(rootView: view)
        if window == nil {
            let window = NSWindow(contentViewController: hosting)
            window.title = "Clips Library"
            window.setContentSize(NSSize(width: 720, height: 480))
            window.center()
            self.window = window
        } else {
            window?.contentViewController = hosting
        }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct ClipsBrowserView: View {
    @State private var clips: [ClipListItem] = []

    struct ClipListItem: Identifiable {
        let id: UUID
        let url: URL
        let createdAt: Date
        let notes: String?
    }

    var body: some View {
        NavigationSplitView {
            List(clips) { clip in
                VStack(alignment: .leading) {
                    Text(clip.createdAt.formatted(date: .abbreviated, time: .shortened))
                    if let notes = clip.notes, !notes.isEmpty {
                        Text(notes).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Clips")
            .toolbar {
                Button("Refresh") { reload() }
                Button("Open folder") {
                    NSWorkspace.shared.open(ClipLibrary.rootDirectory)
                }
            }
        } detail: {
            Text("Select a clip")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear { reload() }
    }

    private func reload() {
        let root = ClipLibrary.rootDirectory
        let fm = FileManager.default
        guard let children = try? fm.contentsOfDirectory(at: root, includingPropertiesForKeys: [.creationDateKey], options: [.skipsHiddenFiles]) else {
            clips = []
            return
        }
        clips = children.compactMap { folder -> ClipListItem? in
            let meta = folder.appendingPathComponent("metadata.json")
            guard let data = try? Data(contentsOf: meta),
                  let record = try? JSONDecoder().decode(ClipRecord.self, from: data) else { return nil }
            return ClipListItem(id: record.id, url: folder, createdAt: record.createdAt, notes: record.notes)
        }
        .sorted { $0.createdAt > $1.createdAt }
    }
}
