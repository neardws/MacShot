#!/usr/bin/env bash
# Create Sparkle EdDSA keys on macOS (Keychain + optional export for CI/release).
# Run locally — never commit the private key.
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "❌ generate_keys requires macOS (Sparkle Keychain integration)."
  exit 1
fi

bash Scripts/fetch-sparkle.sh
GEN=".build/sparkle/2.10.0/bin/generate_keys"

OUT_DIR="${OCTOSHOT_SPARKLE_KEY_DIR:-$HOME/octoshot-private/sparkle}"
PRIV="$OUT_DIR/eddsa_priv.key"
mkdir -p "$OUT_DIR"

if [ -f "$PRIV" ]; then
  echo "⚠️  $PRIV already exists; remove it first to generate a new key."
  exit 1
fi

"$GEN"
"$GEN" -x "$PRIV"
echo ""
echo "✅ Exported private key → $PRIV (gitignored; back up securely)"
echo "   Add to GitHub Actions as secret SPARKLE_EDDSA_KEY (file contents) if needed."
echo ""
echo "Public key for Octoshot/Info.plist SUPublicEDKey:"
"$GEN" -p
