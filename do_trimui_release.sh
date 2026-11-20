#!/bin/bash
#
# SPDX-License-Identifier: MIT
#
# trimui.volkyport.zip: Volkyport as a TrimUI app.
#
#   ./do_trimui_release.sh            from dist/Volkyport.zip (./do_release.sh first)
#   ./do_trimui_release.sh stable  from the latest stable Volkyport.zip on GitHub
#
# Writes dist/trimui.volkyport.zip.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
DIST_DIR="${PM_DIST_DIR:-$REPO_DIR/dist}"

BUILD_DIR="$(mktemp -d "${TMPDIR:-/tmp}/pm-trimui.XXXXXX")"
trap 'rm -rf "$BUILD_DIR"' EXIT
cd "$BUILD_DIR"

if [[ "${1:-}" == "stable" ]]; then
  curl -fL -o version.json "https://github.com/Volkybaba/Volkyport-GUI/releases/latest/download/version.json"
  curl -fL -o Volkyport.zip "$(jq -r '.stable.url' version.json)"
  VOLKYPORT_ZIP="$BUILD_DIR/Volkyport.zip"
else
  VOLKYPORT_ZIP="$DIST_DIR/Volkyport.zip"
fi

if [[ ! -f "$VOLKYPORT_ZIP" ]]; then
  echo "Missing $VOLKYPORT_ZIP, run ./do_release.sh first."
  exit 255
fi

mkdir -p Apps/Volkyport

(
  cd Apps/Volkyport
  unzip -q "$VOLKYPORT_ZIP"

  cd Volkyport
  rm -f Volkyport.sh

  cp trimui/control.txt control.txt
  cp trimui/Volkyport.txt ../launch.sh
  cp trimui/config.json ../config.json
  cp trimui/icon.png ../icon.png

  rm -f tasksetter
  touch tasksetter
)

mkdir -p "$DIST_DIR"
rm -f "$DIST_DIR/trimui.volkyport.zip"
zip -9qr "$DIST_DIR/trimui.volkyport.zip" Apps/
echo "Built $DIST_DIR/trimui.volkyport.zip"
