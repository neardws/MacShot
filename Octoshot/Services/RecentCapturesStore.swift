import Foundation

extension Notification.Name {
    static let octoshotRecentCapturesDidChange = Notification.Name("OctoshotRecentCapturesDidChange")
}

enum RecentCapturesStore {
    private static let key = "recentCapturePaths"
    private static let limit = 8

    static func record(url: URL) {
        var paths = UserDefaults.standard.stringArray(forKey: key) ?? []
        let path = url.path
        paths.removeAll { $0 == path }
        paths.insert(path, at: 0)
        if paths.count > limit {
            paths = Array(paths.prefix(limit))
        }
        UserDefaults.standard.set(paths, forKey: key)
        NotificationCenter.default.post(name: .octoshotRecentCapturesDidChange, object: nil)
    }

    static func recentURLs() -> [URL] {
        let paths = UserDefaults.standard.stringArray(forKey: key) ?? []
        return paths
            .map { URL(fileURLWithPath: $0) }
            .filter { FileManager.default.fileExists(atPath: $0.path) }
    }
}
