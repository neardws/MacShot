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
}
