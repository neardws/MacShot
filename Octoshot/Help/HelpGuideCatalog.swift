import Foundation

enum HelpGuideLanguage: String, CaseIterable, Identifiable {
    case en
    case zh

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .en: return "English"
        case .zh: return "中文"
        }
    }

    var folderName: String { rawValue }
}

struct HelpGuideChapter: Identifiable, Hashable {
    let id: String
    let title: String
    let fileName: String
}

enum HelpGuideCatalog {
    private struct TOC: Decodable {
        let en: [Entry]
        let zh: [Entry]

        struct Entry: Decodable {
            let id: String
            let title: String
        }
    }

    static func chapters(for language: HelpGuideLanguage) -> [HelpGuideChapter] {
        guard let toc = loadTOC() else { return fallbackChapters(for: language) }
        let entries = language == .zh ? toc.zh : toc.en
        return entries.map { HelpGuideChapter(id: $0.id, title: $0.title, fileName: "\($0.id).md") }
    }

    static func markdown(for language: HelpGuideLanguage, chapterID: String) -> String {
        let name = chapterID == "index" ? "index" : chapterID
        let file = "\(name).md"
        if let url = bundleURL(language: language, file: file),
           let text = try? String(contentsOf: url, encoding: .utf8) {
            return text
        }
        return "# \(chapterID)\n\nContent not found in bundle."
    }

    static func search(language: HelpGuideLanguage, query: String) -> [HelpGuideChapter] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return chapters(for: language) }
        return chapters(for: language).filter { chapter in
            if chapter.title.lowercased().contains(q) { return true }
            let body = markdown(for: language, chapterID: chapter.id).lowercased()
            return body.contains(q)
        }
    }

    private static func loadTOC() -> TOC? {
        guard let url = Bundle.main.url(forResource: "toc", withExtension: "json", subdirectory: "HelpGuide")
            ?? Bundle.main.url(forResource: "toc", withExtension: "json", subdirectory: "guide")
        else { return nil }
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(TOC.self, from: data)
    }

    private static func bundleURL(language: HelpGuideLanguage, file: String) -> URL? {
        Bundle.main.url(
            forResource: file,
            withExtension: nil,
            subdirectory: "HelpGuide/\(language.folderName)"
        ) ?? Bundle.main.url(
            forResource: file,
            withExtension: nil,
            subdirectory: "guide/\(language.folderName)"
        )
    }

    private static func fallbackChapters(for language: HelpGuideLanguage) -> [HelpGuideChapter] {
        let titles: [(String, String)]
        switch language {
        case .en:
            titles = [
                ("index", "Overview"),
                ("getting-started", "Getting started"),
                ("capture", "Capture modes"),
            ]
        case .zh:
            titles = [
                ("index", "概览"),
                ("getting-started", "快速开始"),
                ("capture", "捕获模式"),
            ]
        }
        return titles.map { HelpGuideChapter(id: $0.0, title: $0.1, fileName: "\($0.0).md") }
    }
}
