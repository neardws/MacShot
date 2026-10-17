# Agent & CLI

## Command-line tool

After building or installing, use the `octoshot` CLI shipped in `Octoshot.app/Contents/Helpers/octoshot`.

Install a symlink via **Settings → Developer → Install Command Line Tool** (`/usr/local/bin/octoshot`).

## MCP

Run `octoshot mcp` for a stdio MCP server usable from Cursor, Claude Code, and other tools.

## URL scheme

`octoshot://` URLs can trigger capture flows when the app is running (see README on GitHub).

## Permissions

CLI and MCP use the same Screen Recording permission as the GUI. Operations are local-only by default.

## Framework

Core logic lives in **OctoshotCore**, shared between the app, CLI, and MCP.
