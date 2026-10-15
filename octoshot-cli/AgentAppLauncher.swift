import AppKit
import Foundation

enum AgentAppLauncher {
    private static let bundleID = "com.neardws.Octoshot"

    static func openOctoshotURL(_ url: URL) {
        let workspace = NSWorkspace.shared
        if let appURL = workspace.urlForApplication(withBundleIdentifier: bundleID) {
            workspace.open([url], withApplicationAt: appURL, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
        } else {
            workspace.open(url)
        }
    }

    static func recordURL(action: String, mode: String = "fullscreen", format: String = "video", rect: String? = nil) -> URL {
        var items = [
            URLQueryItem(name: "action", value: action),
            URLQueryItem(name: "mode", value: mode),
            URLQueryItem(name: "format", value: format)
        ]
        if let rect {
            items.append(URLQueryItem(name: "rect", value: rect))
        }
        var components = URLComponents()
        components.scheme = "octoshot"
        components.host = "record"
        components.queryItems = items
        return components.url ?? URL(string: "octoshot://record?action=\(action)")!
    }
}
