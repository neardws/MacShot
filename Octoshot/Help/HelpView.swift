import SwiftUI

struct HelpView: View {
    @AppStorage("octoshot.help.language") private var languageRaw = HelpGuideLanguage.en.rawValue
    @State private var selection: String = "index"
    @State private var searchText = ""

    private var language: HelpGuideLanguage {
        HelpGuideLanguage(rawValue: languageRaw) ?? .en
    }

    private var filteredChapters: [HelpGuideChapter] {
        if searchText.isEmpty {
            return HelpGuideCatalog.chapters(for: language)
        }
        return HelpGuideCatalog.search(language: language, query: searchText)
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Section {
                    Picker("Language", selection: $languageRaw) {
                        ForEach(HelpGuideLanguage.allCases) { lang in
                            Text(lang.displayName).tag(lang.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: languageRaw) { _, _ in
                        ensureValidSelection()
                    }
                }
                Section("Contents") {
                    ForEach(filteredChapters) { chapter in
                        Text(chapter.title)
                            .tag(chapter.id)
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 240, max: 280)
            .searchable(text: $searchText, prompt: "Search help")
            .onChange(of: searchText) { _, _ in
                if let first = filteredChapters.first {
                    selection = first.id
                }
            }
        } detail: {
            HelpChapterDetailView(
                language: language,
                chapterID: selection
            )
        }
        .onAppear {
            ensureValidSelection()
        }
    }

    private func ensureValidSelection() {
        let ids = Set(HelpGuideCatalog.chapters(for: language).map(\.id))
        if !ids.contains(selection), let first = HelpGuideCatalog.chapters(for: language).first {
            selection = first.id
        }
    }
}

private struct HelpChapterDetailView: View {
    let language: HelpGuideLanguage
    let chapterID: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                let source = HelpGuideCatalog.markdown(for: language, chapterID: chapterID)
                if let attributed = try? AttributedString(markdown: source) {
                    Text(attributed)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text(source)
                        .font(.body.monospaced())
                        .textSelection(.enabled)
                }
            }
            .padding(24)
            .frame(maxWidth: 720, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .textBackgroundColor))
    }
}
