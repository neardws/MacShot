# Agent 与 CLI

## 命令行工具

构建或安装后，使用 `Octoshot.app/Contents/Helpers/octoshot` 中的 `octoshot`。

在 **设置 → Developer → Install Command Line Tool** 可安装到 `/usr/local/bin/octoshot`。

## MCP

运行 `octoshot mcp` 提供 stdio MCP 服务，供 Cursor、Claude Code 等使用。

## URL Scheme

应用运行时可通过 `octoshot://` 触发捕获（详见 GitHub README）。

## 权限

CLI 与 MCP 与图形界面共用屏幕录制权限；默认仅本机访问。

## 框架

核心逻辑在 **OctoshotCore**，与 App、CLI、MCP 共享。
