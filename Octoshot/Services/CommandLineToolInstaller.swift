import AppKit
import Foundation

enum CommandLineToolInstaller {
    static let installPath = "/usr/local/bin/octoshot"

    /// Path where `octoshot` is installed for MCP/agents (symlink into the app bundle).
    static var installedURL: URL {
        URL(fileURLWithPath: installPath)
    }

    /// `octoshot` shipped inside Octoshot.app (set by build embed script).
    static func bundledToolURL() -> URL? {
        if let auxiliary = Bundle.main.url(forAuxiliaryExecutable: "octoshot") {
            return auxiliary
        }
        let macOS = Bundle.main.bundleURL.appendingPathComponent("Contents/MacOS/octoshot")
        if FileManager.default.fileExists(atPath: macOS.path) {
            return macOS
        }
        return nil
    }

    static func isInstalledCorrectly() -> Bool {
        let fm = FileManager.default
        guard fm.fileExists(atPath: installPath) else { return false }
        guard let bundled = bundledToolURL() else { return false }
        if let dest = try? fm.destinationOfSymbolicLink(atPath: installPath) {
            return URL(fileURLWithPath: dest).standardized == bundled.standardized
        }
        if let attrs = try? fm.attributesOfItem(atPath: installPath),
           let type = attrs[.type] as? FileAttributeType, type == .typeRegular {
            return (try? fm.contentsEqual(atPath: installPath, andPath: bundled.path)) == true
        }
        return false
    }

    @discardableResult
    static func install() throws -> URL {
        guard let source = bundledToolURL() else {
            throw InstallerError.bundledToolMissing
        }
        let dest = URL(fileURLWithPath: installPath)
        let binDir = dest.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: binDir, withIntermediateDirectories: true)

        if FileManager.default.fileExists(atPath: dest.path) {
            try FileManager.default.removeItem(at: dest)
        }
        do {
            try FileManager.default.createSymbolicLink(at: dest, withDestinationURL: source)
        } catch {
            try FileManager.default.copyItem(at: source, to: dest)
        }
        return dest
    }

    static func mcpConfigSnippet() -> String {
        """
        {
          "mcpServers": {
            "octoshot": {
              "command": "\(installPath)",
              "args": ["mcp"]
            }
          }
        }
        """
    }

    enum InstallerError: LocalizedError {
        case bundledToolMissing

        var errorDescription: String? {
            switch self {
            case .bundledToolMissing:
                return "The octoshot command-line tool was not found inside this app bundle. Rebuild Octoshot from Xcode."
            }
        }
    }
}
