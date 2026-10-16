import SwiftUI

struct SettingsRecordingPane: View {
    @ObservedObject private var settings = AppSettings.shared

    var body: some View {
        SettingsFormContainer {
            SettingsPaneHeader(
                title: "Recording",
                subtitle: "Area capture modes, GIF export, scroll capture, and screen recording defaults",
                systemImage: "record.circle"
            )

            Section {
                Toggle("Remember last area capture mode", isOn: $settings.rememberAreaCaptureMode)
                Text("While dragging a region, press S screenshot, R scroll, V video, G GIF, L LaTeX, or T figure/table on the mode bar.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Label("Area selection", systemImage: "viewfinder")
            }

            Section {
                Toggle("Show pointer in recordings", isOn: $settings.recordShowCursor)
                Toggle("Highlight clicks (planned)", isOn: $settings.recordShowClicks)
                    .disabled(true)
                Toggle("Capture system audio (planned)", isOn: $settings.recordSystemAudio)
                    .disabled(true)
                Toggle("Capture microphone (planned)", isOn: $settings.recordMicrophone)
                    .disabled(true)
                Text("Video uses ScreenCaptureKit (H.264 MP4). Audio tracks will land in a follow-up release.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Label("Screen recording", systemImage: "video")
            }

            Section {
                HStack {
                    Text("GIF frame rate")
                    Slider(value: $settings.gifFPS, in: 5...20, step: 1)
                    Text("\(Int(settings.gifFPS)) fps")
                        .monospacedDigit()
                        .frame(width: 52, alignment: .trailing)
                }
                Stepper(value: $settings.gifMaxWidth, in: 320...1920, step: 80) {
                    Text("Max GIF width: \(settings.gifMaxWidth) px")
                }
            } header: {
                Label("GIF export", systemImage: "photo.stack")
            }

            Section {
                Toggle("Auto-scroll while capturing", isOn: $settings.scrollCaptureAutoScroll)
                Text("Requires Accessibility permission to post scroll wheel events. You can always scroll manually during capture.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Label("Scrolling capture", systemImage: "arrow.up.and.down.text.horizontal")
            }
        }
    }
}
