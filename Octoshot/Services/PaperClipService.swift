import AppKit

enum PaperClipService {
    @MainActor
    static func processFigure(image: NSImage) async throws -> URL {
        let source = CaptureSourceRecorder.current()
        let client = OpenAICompatibleClient.fromSettings()
        let description = try await client.completeVisionChat(prompt: AIPrompts.figureDescribe, image: image)
        let tableMarkdown = try? await client.completeVisionChat(prompt: AIPrompts.tableExtract, image: image)
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
