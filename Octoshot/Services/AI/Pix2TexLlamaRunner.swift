import AppKit
import Foundation
import OctoshotCore

enum Pix2TexLlamaRunner {
    static func llamaMtmdCLI() -> URL? {
        let candidates = [
            EmbeddedAIModelPaths.modelsRoot().deletingLastPathComponent().appendingPathComponent("bin/llama-mtmd-cli"),
            URL(fileURLWithPath: "/opt/homebrew/bin/llama-mtmd-cli"),
            URL(fileURLWithPath: "/usr/local/bin/llama-mtmd-cli")
        ]
        for url in candidates where FileManager.default.isExecutableFile(atPath: url.path) {
            return url
        }
        return nil
    }

    static func run(image: NSImage, modelPath: URL) async throws -> String {
        guard let cli = llamaMtmdCLI() else {
            throw EmbeddedAIError.specialistFailed("llama-mtmd-cli not found. Install llama.cpp (mtmd) or use Settings → AI → Install LaTeX engine.")
        }
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
            ]
        )
        try? FileManager.default.removeItem(at: imageURL)
        return output
    }

    private static func runProcess(executable: URL, arguments: [String]) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = executable
            process.arguments = arguments
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            process.terminationHandler = { proc in
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let text = String(data: data, encoding: .utf8) ?? ""
                if proc.terminationStatus == 0 {
                    continuation.resume(returning: text)
                } else {
                    continuation.resume(throwing: EmbeddedAIError.specialistFailed(text.isEmpty ? "llama-mtmd exited \(proc.terminationStatus)" : text))
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
