# MacShot

A native macOS screenshot app inspired by [CleanShot X](https://cleanshot.com/). Built with Swift, SwiftUI + AppKit, and ScreenCaptureKit (macOS 14+).

MacShot 是一款受 CleanShot X 启发的原生 macOS 截图应用，使用 Swift、SwiftUI + AppKit 与 ScreenCaptureKit 构建（需 macOS 14 及以上）。

## Features (MVP)

- Menu bar app (no Dock icon) with global hotkeys: area, window, and fullscreen capture
- Area selection overlay with crosshair and size readout, ESC to cancel, multi-display support
- Quick-access floating thumbnail (corner placement) with copy, save, annotate, close, and drag-out
- Annotation window: arrow, rectangle, text, pixelate, undo, save/copy
- Preferences: save folder, hotkeys, PNG/JPEG format, quick-access corner
- Screen Recording permission prompts and link to System Settings

**默认快捷键（可在偏好设置中修改）**

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
cd MacShot   # repository root
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

## Project layout

| Path | Purpose |
|------|---------|
| `project.yml` | XcodeGen spec (reproducible project) |
| `MacShot/` | Application source |
| `.github/workflows/build.yml` | macOS CI build |

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
