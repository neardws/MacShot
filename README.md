# Octoshot · 章鱼君

**八只手，一次截完**

[Octoshot](https://github.com/neardws/Octoshot) 是一款开源（MIT）的 macOS 原生截图工具：基于 Swift、SwiftUI + AppKit 与 ScreenCaptureKit，强调**本机处理**与**隐私优先**，面向科研写作者与开发者。菜单栏常驻、无 Dock 图标；简体中文系统下显示名为 **章鱼君**。应用图标为原创卡通章鱼 mascot（半眯眼、略带嫌弃的表情，举着取景框——与任何既有版权角色无关）。

## 现已可用

- **区域 / 窗口 / 全屏**截图与全局快捷键
- **快速访问**浮层缩略图：复制、保存、标注、关闭、拖出
- **标注**窗口：箭头、矩形、文字、马赛克、撤销、复制/保存
- **设置**：通用、快捷键、输出、快速访问、权限、关于等

## 路线图

以下能力在开发中或规划中，详见对应 Issue：

| Issue | 功能 |
|-------|------|
| [#2](https://github.com/neardws/Octoshot/issues/2) | 区域选择十字线与放大镜 |
| [#3](https://github.com/neardws/Octoshot/issues/3) | 窗口检测与高亮 |
| [#4](https://github.com/neardws/Octoshot/issues/4) | 快速访问缩略图体验增强 |
| [#5](https://github.com/neardws/Octoshot/issues/5) | 自动脱敏（本机 Vision） |
| [#6](https://github.com/neardws/Octoshot/issues/6) | 询问本机 AI（Ollama 等 OpenAI 兼容接口） |
| [#7](https://github.com/neardws/Octoshot/issues/7) | 截图 → LaTeX |
| [#8](https://github.com/neardws/Octoshot/issues/8) | 论文图/表助手与 Clips 库 |
| [#9](https://github.com/neardws/Octoshot/issues/9) | 开发者模式（取色、标尺、Markdown 粘贴） |
| [#13](https://github.com/neardws/Octoshot/issues/13) | Agent 接口：`octoshot` CLI、stdio MCP、URL scheme、快捷指令 |

### Agent 接口（#13）

构建后可在 DerivedData 或安装路径使用 **`octoshot`** CLI，以及 **`octoshot mcp`**（stdio MCP 服务）。核心能力在 **`OctoshotCore`** 框架中，与 GUI 应用共享。默认仅访问本机；需已授予屏幕录制权限。

**Cursor / Claude Code MCP 配置示例**（路径请改为你本机构建产物）：

```json
{
  "mcpServers": {
    "octoshot": {
      "command": "/path/to/DerivedData/.../octoshot",
      "args": ["mcp"]
    }
  }
}
```

Claude Desktop（`claude_desktop_config.json`）同样使用 `command` + `args: ["mcp"]`。工具包括：`capture_screen`、`capture_window`、`list_windows`、`list_displays`、`ocr`、`auto_redact`、`ask_ai`、`to_latex`、`extract_table`、`annotate`。

URL 示例：`octoshot://capture?mode=fullscreen`（区域/窗口模式会打开应用内交互流程）。

## 环境要求

- macOS **14.0** 或更高
- Xcode **15+**（Swift 5.9）
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)（生成 Xcode 工程）

## 构建与运行

```bash
brew install xcodegen
git clone https://github.com/neardws/Octoshot.git
cd Octoshot
xcodegen generate
open Octoshot.xcodeproj
```

在 Xcode 中选择 **Octoshot** scheme，按 **⌘R** 运行。

命令行构建：

```bash
xcodegen generate
xcodebuild -scheme Octoshot -configuration Debug -destination 'platform=macOS' build
```

首次使用请在 **系统设置 → 隐私与安全性 → 屏幕录制** 中允许 Octoshot（简体系统列表中可能显示为 **章鱼君**）。

## 签名与屏幕录制权限

macOS 将**屏幕录制**权限绑定到应用的 **Bundle ID 与代码签名**。请使用稳定的 **Apple Development** 签名进行本地调试；避免长期依赖 ad-hoc 签名（`CODE_SIGN_IDENTITY=-`），否则权限状态容易与系统设置不一致。

- **Bundle ID**：`com.neardws.Octoshot`
- 从旧版 MacShot 更名后，即使曾在旧 Bundle ID 下授权，也需在系统设置中**重新允许** Octoshot。

重置屏幕录制权限（更换签名、迁移 Bundle ID 或权限卡住时）：

```bash
tccutil reset ScreenCapture com.neardws.Octoshot
```

然后重新打开应用并在 **隐私与安全性 → 屏幕录制** 中启用。应用内会通过 **ScreenCaptureKit**（`SCShareableContent`）校验权限，因 CoreGraphics 预检 API 可能滞后于真实 TCC 状态。

## 参与贡献

欢迎 Issue 与 Pull Request：[neardws/Octoshot](https://github.com/neardws/Octoshot)。请先 `xcodegen generate` 再构建；修改应用图标可运行 `python3 Scripts/generate_icons.py`。

## 许可证

[MIT License](LICENSE) · Copyright © 2026 [neardws](https://github.com/neardws)

---

# Octoshot · 章鱼君

**Eight arms, one shot.**

[Octoshot](https://github.com/neardws/Octoshot) is an open-source (**MIT**) native macOS screenshot app built with Swift, SwiftUI + AppKit, and ScreenCaptureKit. It is **on-device** and **privacy-first**, aimed at **researchers and developers**. The app lives in the menu bar (no Dock icon). On Simplified Chinese systems the display name is **章鱼君**. The mascot is an **original** cartoon octopus with a deadpan, half-lidded, slightly grumpy look, holding a crop viewfinder—not based on any copyrighted character.

## Available now

- **Area, window, and fullscreen** capture with global hotkeys
- **Quick access** floating thumbnail: copy, save, annotate, close, drag-out
- **Annotate** window: arrow, rectangle, text, pixelate, undo, copy/save
- **Settings**: General, Shortcuts, Output, Quick Access, Permissions, About, and more

## Roadmap

Planned or in-progress work is tracked in GitHub issues:

| Issue | Feature |
|-------|---------|
| [#2](https://github.com/neardws/Octoshot/issues/2) | Area crosshair & loupe |
| [#3](https://github.com/neardws/Octoshot/issues/3) | Window detection & highlight |
| [#4](https://github.com/neardws/Octoshot/issues/4) | Quick-access thumbnail polish |
| [#5](https://github.com/neardws/Octoshot/issues/5) | Auto-redact (on-device Vision) |
| [#6](https://github.com/neardws/Octoshot/issues/6) | Ask local AI (Ollama / OpenAI-compatible) |
| [#7](https://github.com/neardws/Octoshot/issues/7) | Screenshot → LaTeX |
| [#8](https://github.com/neardws/Octoshot/issues/8) | Paper figure/table assistant & Clips library |
| [#9](https://github.com/neardws/Octoshot/issues/9) | Developer mode (color picker, ruler, Markdown for issues) |

## Requirements

- macOS **14.0** or later
- Xcode **15+** (Swift 5.9)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

## Build & run

```bash
brew install xcodegen
git clone https://github.com/neardws/Octoshot.git
cd Octoshot
xcodegen generate
open Octoshot.xcodeproj
```

Select the **Octoshot** scheme in Xcode and press **⌘R**.

```bash
xcodegen generate
xcodebuild -scheme Octoshot -configuration Debug -destination 'platform=macOS' build
```

Grant **Screen Recording** under **System Settings → Privacy & Security** on first run (may appear as **章鱼君** in Chinese locales).

## Signing & Screen Recording (TCC)

macOS ties Screen Recording to your app’s **bundle ID and code signature**. Use a stable **Apple Development** identity for local builds; ad-hoc signing often breaks or confuses TCC.

- **Bundle ID**: `com.neardws.Octoshot`
- After renaming from legacy MacShot, you must **re-grant** Screen Recording even if an older build was allowed.

```bash
tccutil reset ScreenCapture com.neardws.Octoshot
```

Relaunch the app and enable it again under **Privacy & Security → Screen Recording**. The UI verifies access via **ScreenCaptureKit** because `CGPreflightScreenCaptureAccess()` can lag TCC.

## Contributing

Issues and pull requests are welcome at [neardws/Octoshot](https://github.com/neardws/Octoshot). Run `xcodegen generate` before building; regenerate icons with `python3 Scripts/generate_icons.py` when needed.

## License

[MIT License](LICENSE) · Copyright © 2026 [neardws](https://github.com/neardws)
