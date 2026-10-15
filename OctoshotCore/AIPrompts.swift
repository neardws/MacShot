import Foundation

public enum AIPrompts {
    public static func explain() -> String {
        "Explain what is shown in this screenshot clearly and concisely."
    }

    public static func summarize() -> String {
        "Summarize the key information in this screenshot in bullet points."
    }

    public static func translate(to language: String) -> String {
        "Translate all visible text in this screenshot to \(language). Preserve layout hints where useful."
    }

    public static let latex = """
    You are a LaTeX OCR engine. Return ONLY valid LaTeX math markup for the formula in the image.
    Do not include markdown fences or explanations. Use amsmath-compatible syntax when needed.
    """

    public static let tableExtract = """
    Extract the table in this image. Return GitHub-flavored Markdown table only. If not a table, return a short description.
    """

    public static let figureDescribe = """
    Describe this academic figure briefly and list any axis labels, legends, and numeric trends.
    """
}
