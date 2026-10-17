import Foundation

enum OctoshotL10n {
    static var ocrAction: String {
        String(localized: "OCR", comment: "Quick action: recognize text in screenshot")
    }

    static var ocrWindowTitle: String {
        String(localized: "Recognize Text", comment: "OCR result window title")
    }

    static var ocrRecognizing: String {
        String(localized: "Recognizing…", comment: "OCR in progress")
    }

    static var ocrRecognizeAgain: String {
        String(localized: "Recognize Again", comment: "Re-run OCR on image")
    }

    static var ocrSelectAll: String {
        String(localized: "Select All", comment: "Select all recognized text")
    }

    static var ocrCopy: String {
        String(localized: "Copy", comment: "Copy recognized text")
    }

    static var ocrNoTextFound: String {
        String(localized: "No text found in this image.", comment: "OCR empty result")
    }

    static var ocrRecognitionFailed: String {
        String(localized: "Text recognition failed.", comment: "OCR error headline")
    }

    static var historyWindowTitle: String {
        String(localized: "Screenshot History", comment: "History browser window title")
    }

    static var historyMenuItem: String {
        String(localized: "Screenshot History…", comment: "Menu item to open history")
    }

    static var historyEmptySelection: String {
        String(localized: "Select a screenshot", comment: "History detail placeholder")
    }

    static var historyEmptyLibrary: String {
        String(localized: "No screenshots in the save folder", comment: "History empty state")
    }

    static var historyRefresh: String {
        String(localized: "Refresh", comment: "Reload history list")
    }

    static var historyOpenFolder: String {
        String(localized: "Open Save Folder", comment: "Reveal screenshot save directory")
    }

    static var historyDelete: String {
        String(localized: "Delete", comment: "Delete screenshot file")
    }

    static var historyRevealInFinder: String {
        String(localized: "Show in Finder", comment: "Reveal file in Finder")
    }

    static var historyDeleteConfirmTitle: String {
        String(localized: "Delete screenshot?", comment: "Delete confirmation title")
    }

    static func historyDeleteConfirmMessage(_ name: String) -> String {
        String(
            format: String(localized: "%@ will be moved to the Trash.", comment: "Delete confirmation body"),
            name
        )
    }

    static var historyDeleteFailed: String {
        String(localized: "Could not delete the file.", comment: "Delete error headline")
    }

    static var historyPinAction: String {
        String(localized: "Pin to Screen", comment: "Pin screenshot on desktop")
    }

    static var historyCancel: String {
        String(localized: "Cancel", comment: "Cancel destructive action")
    }

    static var checkForUpdates: String {
        String(localized: "Check for Updates…", comment: "Sparkle manual update check")
    }

    // MARK: - Quick access panel

    static var quickAccessCopy: String {
        String(localized: "Copy to Clipboard", comment: "Quick access: copy screenshot")
    }

    static var quickAccessSave: String {
        String(localized: "Save to Disk", comment: "Quick access: save screenshot")
    }

    static var quickAccessAnnotate: String {
        String(localized: "Annotate", comment: "Quick access: open annotation editor")
    }

    static var quickAccessPin: String {
        String(localized: "Pin to Screen", comment: "Quick access: pin screenshot on desktop")
    }

    static var quickAccessAskAI: String {
        String(localized: "Ask AI", comment: "Quick access: open local AI assistant")
    }

    static var quickAccessCopyMarkdown: String {
        String(localized: "Copy Markdown", comment: "Quick access: copy Markdown image snippet")
    }

    static var quickAccessCopyPath: String {
        String(localized: "Copy File Path", comment: "Quick access: copy saved file path")
    }

    static var quickAccessClose: String {
        String(localized: "Dismiss", comment: "Quick access: close panel")
    }
}
