#!/usr/bin/env bash
#
# SimForge installer / updater for macOS (Apple Silicon).
#
# Students run ONE line in Terminal:
#
#   curl -fsSL https://raw.githubusercontent.com/Niel-TCH/simforge-releases/main/update.sh | bash
#
# It installs SimForge on first run and updates it on every later run: reads
# the latest version, stops if it is already installed, quits SimForge,
# downloads the .dmg and copies SimForge.app into /Applications (or
# ~/Applications when /Applications is not writable).
#
# Downloads use github.com/<repo>/releases/latest/download/<file>, not the
# GitHub API, which allows only 60 calls an hour per IP (one classroom = one IP).
#
# SIMFORGE_APPS=<dir> installs somewhere else (used for testing).
# SIMFORGE_FORCE=1 reinstalls even when the version matches.

set -euo pipefail

REPO="Niel-TCH/simforge-releases"
BASE="https://github.com/$REPO/releases/latest/download"

echo ""
echo "SimForge updater"

if [ "$(uname -s)" != "Darwin" ]; then
  echo "This updater is for macOS. On Windows, run in PowerShell:"
  echo "  irm https://raw.githubusercontent.com/$REPO/main/update.ps1 | iex"
  exit 1
fi
if [ "$(uname -m)" != "arm64" ]; then
  echo "SimForge for Mac is built for Apple Silicon (M1 or newer); this Mac is $(uname -m)."
  exit 1
fi

if [ -n "${SIMFORGE_APPS:-}" ]; then
  APPS="$SIMFORGE_APPS"
elif [ -w /Applications ]; then
  APPS="/Applications"
else
  APPS="$HOME/Applications"
fi
mkdir -p "$APPS"
APP="$APPS/SimForge.app"

if ! LATEST="$(curl -fsSL "$BASE/version.txt" | tr -d '[:space:]')" || [ -z "$LATEST" ]; then
  echo "Could not reach GitHub. Check your internet connection and try again."
  exit 1
fi

CURRENT=""
if [ -f "$APP/Contents/Info.plist" ]; then
  CURRENT="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP/Contents/Info.plist" 2>/dev/null || true)"
fi
if [ "$CURRENT" = "$LATEST" ] && [ -z "${SIMFORGE_FORCE:-}" ]; then
  echo "SimForge $CURRENT is already the latest version."
  exit 0
fi
if [ -n "$CURRENT" ]; then echo "Updating SimForge $CURRENT -> $LATEST"; else echo "Installing SimForge $LATEST"; fi

TMP="$(mktemp -d)"
MNT="$TMP/mnt"
cleanup() {
  hdiutil detach "$MNT" -quiet 2>/dev/null || true
  rm -rf "$TMP"
}
trap cleanup EXIT

echo "  downloading..."
curl -fL --progress-bar "$BASE/SimForge-macos-arm64.dmg" -o "$TMP/SimForge.dmg"
mkdir -p "$MNT"
hdiutil attach "$TMP/SimForge.dmg" -nobrowse -readonly -quiet -mountpoint "$MNT"
[ -d "$MNT/SimForge.app" ] || { echo "Update failed: the download did not contain SimForge.app"; exit 1; }

# Quit a running SimForge so the bundle can be replaced.
if pgrep -x simforge >/dev/null 2>&1; then
  echo "  closing SimForge (save your work first next time)..."
  osascript -e 'quit app "SimForge"' 2>/dev/null || true
  sleep 2
  pkill -x simforge 2>/dev/null || true
fi

# Copy beside the old app first, then swap, so a failed copy never leaves
# the student without SimForge.
rm -rf "$APP.new"
cp -R "$MNT/SimForge.app" "$APP.new"
# The app is unsigned: clear the quarantine flag, or macOS refuses to open it.
xattr -cr "$APP.new" 2>/dev/null || true
rm -rf "$APP"
mv "$APP.new" "$APP"

echo ""
echo "SimForge $LATEST is installed in $APPS"
echo "Open it from Launchpad or with:  open \"$APP\""

if ! command -v python3 >/dev/null 2>&1 || ! python3 -c 'import sys; sys.exit(sys.version_info < (3, 9))' 2>/dev/null; then
  echo ""
  echo "Python 3.9 or newer was not found. SimForge needs it to run code:"
  echo "  run  xcode-select --install  or install Python from https://www.python.org/downloads/"
fi
