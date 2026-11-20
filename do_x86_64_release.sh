#!/bin/bash
#
# SPDX-License-Identifier: MIT
#
# retrodeck.volkyport.zip: Volkyport for RetroDECK.
#
#   ./do_x86_64_release.sh            from dist/Volkyport.zip (./do_release.sh first)
#   ./do_x86_64_release.sh CHANNEL from the latest alpha/beta/stable Volkyport.zip on GitHub
#
# Writes dist/retrodeck.volkyport.zip.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
DIST_DIR="${PM_DIST_DIR:-$REPO_DIR/dist}"

BUILD_DIR="$(mktemp -d "${TMPDIR:-/tmp}/pm-retrodeck.XXXXXX")"
trap 'rm -rf "$BUILD_DIR"' EXIT
cd "$BUILD_DIR"

case "${1:-}" in
  alpha|beta|stable)
    curl -fL -o version.json "https://github.com/Volkybaba/Volkyport-GUI/releases/latest/download/version.json"
    curl -fL -o Volkyport.zip "$(jq -r ".$1.url" version.json)"
    VOLKYPORT_ZIP="$BUILD_DIR/Volkyport.zip"
    ;;
  *)
    VOLKYPORT_ZIP="$DIST_DIR/Volkyport.zip"
    ;;
esac

if [[ ! -f "$VOLKYPORT_ZIP" ]]; then
  echo "Missing $VOLKYPORT_ZIP, run ./do_release.sh first."
  exit 255
fi

mkdir -p RD_PM/

(
  cd RD_PM/
  unzip -q "$VOLKYPORT_ZIP"

  cd Volkyport
  cp retrodeck/control.txt control.txt
  cp retrodeck/Volkyport.txt Volkyport.sh
  rm -f tasksetter
  touch tasksetter
)

mkdir -p "$DIST_DIR"
rm -f "$DIST_DIR/retrodeck.volkyport.zip"
(cd RD_PM && zip -9qr "$DIST_DIR/retrodeck.volkyport.zip" Volkyport/)
echo "Built $DIST_DIR/retrodeck.volkyport.zip"
