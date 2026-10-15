import SwiftUI
import OctoshotCore

struct RedactionReviewView: View {
    @Binding var candidates: [RedactionCandidate]
    var onApply: () -> Void
    var onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Auto Redact")
                .font(.headline)
            Text("Toggle detections to include before applying pixelation.")
                .font(.caption)
                .foregroundStyle(.secondary)

            List {
                ForEach($candidates) { $candidate in
                    Toggle(isOn: $candidate.isEnabled) {
                        VStack(alignment: .leading) {
                            Text(candidate.kind.label)
                                .font(.subheadline.weight(.semibold))
                            Text(candidate.detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .frame(minHeight: 180)

            HStack {
                Button("Cancel", action: onCancel)
                Spacer()
                Button("Apply Redaction", action: onApply)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 360)
    }
}
