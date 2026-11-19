#!/bin/bash
#
# SPDX-License-Identifier: MIT
#
# muos.volkyport.zip: Volkyport laid out for muOS images.
#
#   ./do_muos_release.sh            from dist/Volkyport.zip (./do_release.sh first)
#   ./do_muos_release.sh stable  from the latest stable Volkyport.zip on GitHub
#
# Writes dist/muos.volkyport.zip.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
DIST_DIR="${PM_DIST_DIR:-$REPO_DIR/dist}"

BUILD_DIR="$(mktemp -d "${TMPDIR:-/tmp}/pm-muos.XXXXXX")"
trap 'rm -rf "$BUILD_DIR"' EXIT
cd "$BUILD_DIR"

if [[ "${1:-}" == "stable" ]]; then
  curl -fL -o version.json "https://github.com/Volkybaba/PortMaster-GUI/releases/latest/download/version.json"
  curl -fL -o Volkyport.zip "$(jq -r '.stable.url' version.json)"
  VOLKYPORT_ZIP="$BUILD_DIR/Volkyport.zip"
else
  VOLKYPORT_ZIP="$DIST_DIR/Volkyport.zip"
fi

if [[ ! -f "$VOLKYPORT_ZIP" ]]; then
  echo "Missing $VOLKYPORT_ZIP, run ./do_release.sh first."
  exit 255
fi

mkdir -p mnt/mmc/MUOS/ roms/ports/Volkyport/

(
  cd mnt/mmc/MUOS/
  unzip -q "$VOLKYPORT_ZIP"

  cd Volkyport
  cp muos/control.txt control.txt
  cp muos/control.txt "$BUILD_DIR/roms/ports/Volkyport/control.txt"
  cp muos/Volkyport.txt Volkyport.sh
  rm -f tasksetter
  touch tasksetter
)

mkdir -p "$DIST_DIR"
rm -f "$DIST_DIR/muos.volkyport.zip"
zip -9qr "$DIST_DIR/muos.volkyport.zip" roms/ mnt/
echo "Built $DIST_DIR/muos.volkyport.zip"
