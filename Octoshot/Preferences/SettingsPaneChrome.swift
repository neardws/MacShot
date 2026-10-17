import SwiftUI

struct SettingsPaneHeader: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title2.bold())
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.bottom, 8)
    }
}

struct SettingsFormContainer<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        Form {
            content()
        }
        .formStyle(.grouped)
        .padding()
    }
}
