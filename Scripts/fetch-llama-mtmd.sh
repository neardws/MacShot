#!/usr/bin/env bash
# Downloads a pinned llama.cpp macOS binary tarball and exposes llama-mtmd-cli for embedding.
set -euo pipefail

LLAMA_CPP_RELEASE="${LLAMA_CPP_RELEASE:-b11514}"
DEST="${1:-${PROJECT_DIR:-$(pwd)}/build/llama-mtmd}"

ARCH="$(uname -m)"
case "$ARCH" in
  arm64) TARBALL="llama-${LLAMA_CPP_RELEASE}-bin-macos-arm64.tar.gz" ;;
  x86_64) TARBALL="llama-${LLAMA_CPP_RELEASE}-bin-macos-x64.tar.gz" ;;
  *)
    echo "Unsupported architecture: $ARCH" >&2
    exit 1
    ;;
esac

URL="https://github.com/ggml-org/llama.cpp/releases/download/${LLAMA_CPP_RELEASE}/${TARBALL}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Fetching ${URL}"
curl -fsSL "$URL" -o "$TMP/archive.tar.gz"
mkdir -p "$TMP/extract" "$DEST"
tar -xzf "$TMP/archive.tar.gz" -C "$TMP/extract"

CLI="$(find "$TMP/extract" -type f -name 'llama-mtmd-cli' | head -1)"
if [[ -z "$CLI" ]]; then
  echo "llama-mtmd-cli not found in archive" >&2
  exit 1
fi

BIN_DIR="$(dirname "$CLI")"
mkdir -p "$DEST/bin"
cp -f "$CLI" "$DEST/bin/llama-mtmd-cli"
chmod +x "$DEST/bin/llama-mtmd-cli"
# Ship adjacent dylibs the CLI may load.
find "$BIN_DIR" -maxdepth 1 -name '*.dylib' -exec cp -f {} "$DEST/bin/" \;

echo "Installed llama-mtmd-cli at $DEST/bin/llama-mtmd-cli"
