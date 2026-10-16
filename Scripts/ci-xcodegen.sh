#!/usr/bin/env bash
# CI: stub MLX (no mlx-swift-lm SPM) while keeping app + CLI buildable.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cp "$ROOT/Config/EmbeddedAI.ci.xcconfig" "$ROOT/Config/EmbeddedAI.xcconfig"
xcodegen generate --spec "$ROOT/project.ci.yml"
