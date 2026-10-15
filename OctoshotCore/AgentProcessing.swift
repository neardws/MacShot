import AppKit
import Foundation

public enum AgentProcessing {
    public static func autoRedact(image: NSImage) async throws -> NSImage {
        let candidates = try await RedactionDetector.detect(in: image, settings: AgentConfiguration.redactionSettings())
        return RedactionCompositor.apply(candidates.filter(\.isEnabled), to: image)
    }

    public static func askAI(image: NSImage, prompt: String) async throws -> String {
        let reachable = await AgentOllama.isReachable()
        let settings = EmbeddedAISettings.fromUserDefaults(ollamaReachable: reachable)
        return try await EmbeddedAIRouter.askAI(image: image, prompt: prompt, settings: settings)
    }

    public static func toLaTeX(image: NSImage, prompt: String? = nil) async throws -> String {
        let p = prompt ?? UserDefaults.standard.string(forKey: "aiLatexPrompt") ?? AIPrompts.latex
        let reachable = await AgentOllama.isReachable()
        let settings = EmbeddedAISettings.fromUserDefaults(ollamaReachable: reachable)
        return try await EmbeddedAIRouter.toLaTeX(image: image, vlmPrompt: p, settings: settings)
    }

    public static func extractTable(image: NSImage) async throws -> String {
        let reachable = await AgentOllama.isReachable()
        let settings = EmbeddedAISettings.fromUserDefaults(ollamaReachable: reachable)
        return try await EmbeddedAIRouter.extractTable(image: image, settings: settings)
    }

    public static func extractTableAndSaveClip(image: NSImage) async throws -> URL {
        let source = CaptureSourceRecorder.current()
        let reachable = await AgentOllama.isReachable()
        let settings = EmbeddedAISettings.fromUserDefaults(ollamaReachable: reachable)
        let description = try await EmbeddedAIRouter.askAI(image: image, prompt: AIPrompts.figureDescribe, settings: settings)
        let tableMarkdown = try? await EmbeddedAIRouter.extractTable(image: image, settings: settings)
        let csv = tableMarkdown.flatMap(convertMarkdownTableToCSV)
        return try ClipLibrary.save(
            image: image,
            source: source,
            tableMarkdown: tableMarkdown,
            tableCSV: csv,
            notes: description
        )
    }

    private static func convertMarkdownTableToCSV(_ markdown: String) -> String? {
        let lines = markdown.split(separator: "\n").map(String.init)
        let rows = lines.filter { $0.contains("|") && !$0.contains("---") }
        guard !rows.isEmpty else { return nil }
        return rows.map { row in
            row.split(separator: "|")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
                .joined(separator: ",")
        }.joined(separator: "\n")
    }
}

/// Applies redaction boxes by drawing solid black fills (agent-friendly; no pixelate shader).
public enum RedactionCompositor {
    public static func apply(_ candidates: [RedactionCandidate], to image: NSImage) -> NSImage {
        let size = image.size
        let output = NSImage(size: size)
        output.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: size))
        NSColor.black.setFill()
        for c in candidates {
            NSBezierPath(rect: c.rect).fill()
        }
        output.unlockFocus()
        return output
    }
}
