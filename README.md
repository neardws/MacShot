# MacShot

A native macOS screenshot app inspired by [CleanShot X](https://cleanshot.com/). Built with Swift, SwiftUI + AppKit, and ScreenCaptureKit (macOS 14+).

MacShot 是一款受 CleanShot X 启发的原生 macOS 截图应用，使用 Swift、SwiftUI + AppKit 与 ScreenCaptureKit 构建（需 macOS 14 及以上）。

## Features (MVP)

- Menu bar app (no Dock icon) with global hotkeys: area, window, and fullscreen capture
- Area selection overlay with crosshair and size readout, ESC to cancel, multi-display support
- Quick-access floating thumbnail (corner placement) with copy, save, annotate, close, and drag-out
- Annotation window: arrow, rectangle, text, pixelate, undo, save/copy
- Settings window (⌘,): General, Shortcuts, Output, Quick Access, Permissions, About
- Custom app icon and template menu bar icon
- Screen Recording permission prompts and link to System Settings

**默认快捷键（可在「Shortcuts」设置中修改）**

| Action | Default |
|--------|---------|
| Area | ⌘⇧5 |
| Window | ⌘⇧6 |
| Fullscreen | ⌘⇧7 |

## Requirements

- macOS 14.0 or later
- Xcode 15+ (Swift 5.9)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (to generate the Xcode project)
- Screen Recording permission for MacShot

## Build & Run

```bash
brew install xcodegen
# clone repository, then from repo root:
xcodegen generate
open MacShot.xcodeproj
```

In Xcode, select the **MacShot** scheme and press **Run** (⌘R).

首次运行请在 **系统设置 → 隐私与安全性 → 屏幕录制** 中允许 MacShot。

### Command-line build

```bash
xcodegen generate
xcodebuild -scheme MacShot -configuration Debug -destination 'platform=macOS' build
```

### Code signing & Screen Recording (TCC)

macOS ties **Screen Recording** permission to your app’s **code signature**. If every debug build is **ad-hoc** signed (`CODE_SIGN_IDENTITY=-`), the bundle identity changes and System Settings may show MacShot as allowed while capture APIs still fail or `CGPreflightScreenCaptureAccess()` stays `false`.

**Recommended for local development**

1. Open `MacShot.xcodeproj` in Xcode.
2. Select the **MacShot** target → **Signing & Capabilities**.
3. Enable **Automatically manage signing** and choose your **Apple Development** team (or a stable self-signed certificate you control).
4. Run from Xcode or `open` the signed `.app` in DerivedData — avoid ad-hoc `CODE_SIGN_IDENTITY=-` for permission testing.

Bundle ID: `com.macshot.MacShot`

**Reset Screen Recording permission** (after changing signing identity or if status is stuck):

```bash
tccutil reset ScreenCapture com.macshot.MacShot
```

Then launch MacShot again and re-enable it under **Privacy & Security → Screen Recording**.

MacShot’s UI checks access by calling **ScreenCaptureKit** (`SCShareableContent`) because the CoreGraphics preflight API can lag behind the real TCC state.

### 代码签名与屏幕录制权限

调试时请使用稳定的 **Apple Development** 签名，不要使用 ad-hoc 签名，否则系统权限可能失效。重置权限：

```bash
tccutil reset ScreenCapture com.macshot.MacShot
```

## Project layout

| Path | Purpose |
|------|---------|
| `project.yml` | XcodeGen spec (reproducible project) |
| `MacShot/` | Application source |
| `.github/workflows/build.yml` | macOS CI build |

## Signature features (beta)

- **Auto-redact** (Vision on-device): phones, emails, IDs, cards, API keys, IPs, faces — review toggles in Annotate
- **Ask local AI** (OpenAI-compatible, default Ollama `http://localhost:11434/v1`): Explain / Summarize / Translate / custom prompt with streaming
- **Screenshot → LaTeX**: area capture from menu, local vision model returns LaTeX
- **Paper figure/table clips**: save captures to `Pictures/MacShot Clips` with metadata JSON (+ optional table Markdown/CSV via local AI)

Configure under **Settings → AI** and **Settings → Redaction**.

## Roadmap (not in MVP)

- Scrolling capture
- Screen recording / GIF export
- OCR via Vision
- Hide desktop icons during capture
- Pin screenshot on screen
- Cloud upload

## CI

GitHub Actions runs on `macos-latest` for every push and pull request: installs XcodeGen, generates the project, and builds with `xcodebuild` (`CODE_SIGNING_ALLOWED=NO`).

## License

MacShot is open source software released under the [MIT License](LICENSE). Copyright (c) 2026 [neardws](https://github.com/neardws).

## 许可证

MacShot 以 [MIT 许可证](LICENSE) 发布，版权 (c) 2026 [neardws](https://github.com/neardws)。
