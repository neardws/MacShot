import SwiftUI
import OctoshotCore

struct DeveloperSettingsPane: View {
    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        Form {
            Toggle("Developer mode", isOn: $settings.developerModeEnabled)
            Text("Enables color picking during area capture (loupe + press C to copy hex), a measure/ruler tool in Annotate, and Markdown/path copy actions for GitHub issues.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Section {
                Toggle("Use absolute path in Markdown snippets", isOn: $settings.markdownImageUseAbsolutePath)
                Text("When off, snippets use the filename only — paste after uploading the image to your issue or repo.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
