import AppKit
import Foundation
import OctoshotCore

enum Pix2TexLlamaRunner {
    static func bundledCLI() -> URL? {
        if let url = Bundle.main.url(forResource: "llama-mtmd-cli", withExtension: nil, subdirectory: "Helpers"),
           FileManager.default.isExecutableFile(atPath: url.path) {
            return url
        }
        let helpers = Bundle.main.bundleURL.appendingPathComponent("Contents/Helpers/llama-mtmd-cli")
        if FileManager.default.isExecutableFile(atPath: helpers.path) {
            return helpers
        }
        return nil
    }

    static func llamaMtmdCLI() -> URL? {
        if let bundled = bundledCLI() { return bundled }
        let appSupport = EmbeddedAIModelPaths.latexEngineCLI
        if FileManager.default.isExecutableFile(atPath: appSupport.path) {
            return appSupport
        }
        return nil
    }

    static func run(image: NSImage, modelPath: URL) async throws -> String {
        let cli = try await resolveCLI()
        let imageURL = FileManager.default.temporaryDirectory.appendingPathComponent("octoshot-pix2tex-\(UUID().uuidString).png")
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else {
            throw EmbeddedAIError.specialistFailed("Could not encode image")
        }
        try png.write(to: imageURL)

        let output = try await runProcess(
            executable: cli,
            arguments: [
                "-m", modelPath.path,
                "--image", imageURL.path,
                "-p", "latex",
                "-n", "256",
                "--temp", "0.1"
            ],
            workingDirectory: cli.deletingLastPathComponent()
        )
        try? FileManager.default.removeItem(at: imageURL)
        return output
    }

    private static func resolveCLI() async throws -> URL {
        if let cli = llamaMtmdCLI() { return cli }
        return try await LaTeXEngineInstaller.shared.ensureCLI()
    }

    private static func runProcess(executable: URL, arguments: [String], workingDirectory: URL) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = executable
            process.arguments = arguments
            process.currentDirectoryURL = workingDirectory
            var env = ProcessInfo.processInfo.environment
            env["DYLD_LIBRARY_PATH"] = workingDirectory.path
            process.environment = env
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            process.terminationHandler = { proc in
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let text = String(data: data, encoding: .utf8) ?? ""
                if proc.terminationStatus == 0 {
                    continuation.resume(returning: text)
                } else {
                    continuation.resume(throwing: EmbeddedAIError.specialistFailed(
                        text.isEmpty ? "llama-mtmd exited \(proc.terminationStatus)" : text
                    ))
                }
            }
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
