#!/usr/bin/env bash
# Download Sparkle 2.10 release tools (generate_appcast, generate_keys) into .build/sparkle/.
# Not required for Xcode SPM builds; used by generate-appcast.sh and release signing on macOS.
set -euo pipefail
cd "$(dirname "$0")/.."

SPARKLE_VER=2.10.0
SPARKLE_TAR_SHA=c2bf58aa8387266ac179357b1415d6f2635f044da8be41042af32425dae6da0c
TOOLS=".build/sparkle/$SPARKLE_VER"
mkdir -p "$TOOLS"

SZ="$TOOLS/Sparkle-$SPARKLE_VER.tar.xz"
if [ ! -x "$TOOLS/bin/generate_appcast" ]; then
  [ -f "$SZ" ] || curl -fsSL -o "$SZ" "https://github.com/sparkle-project/Sparkle/releases/download/$SPARKLE_VER/Sparkle-$SPARKLE_VER.tar.xz"
  got=$(shasum -a 256 "$SZ" | cut -d' ' -f1)
  [ "$got" = "$SPARKLE_TAR_SHA" ] || { echo "❌ Sparkle tar checksum mismatch: $got"; rm -f "$SZ"; exit 1; }
  tar -xJf "$SZ" -C "$TOOLS"
  echo "✅ Sparkle tools → $TOOLS/bin"
else
  echo "✅ Sparkle tools already present at $TOOLS/bin"
fi
