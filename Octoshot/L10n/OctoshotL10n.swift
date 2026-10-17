import Foundation

/// Lightweight bilingual strings (English + Simplified Chinese) for UI not yet in xcstrings.
enum OctoshotL10n {
    static var usesChinese: Bool {
        if let first = Bundle.main.preferredLocalizations.first, first.hasPrefix("zh") {
            return true
        }
        return Locale.preferredLanguages.first?.hasPrefix("zh") == true
    }

    static func pick(_ english: String, _ chinese: String) -> String {
        usesChinese ? chinese : english
    }

    enum History {
        static var windowTitle: String {
            pick("Screenshot History", "截图历史")
        }

        static var menuItem: String {
            pick("Screenshot History…", "截图历史…")
        }

        static var emptySelection: String {
            pick("Select a screenshot", "选择一张截图")
        }

        static var emptyLibrary: String {
            pick("No screenshots in the save folder", "保存文件夹中暂无截图")
        }

        static var refresh: String {
            pick("Refresh", "刷新")
        }

        static var openFolder: String {
            pick("Open Save Folder", "打开保存文件夹")
        }

        static var copy: String {
            pick("Copy", "复制")
        }

        static var delete: String {
            pick("Delete", "删除")
        }

        static var revealInFinder: String {
            pick("Show in Finder", "在 Finder 中显示")
        }

        static var deleteConfirmTitle: String {
            pick("Delete screenshot?", "删除这张截图？")
        }

        static func deleteConfirmMessage(_ name: String) -> String {
            pick(
                "“\(name)” will be moved to the Trash.",
                "“\(name)” 将移到废纸篓。"
            )
        }

        static var deleteFailed: String {
            pick("Could not delete the file.", "无法删除该文件。")
        }
    }
}
