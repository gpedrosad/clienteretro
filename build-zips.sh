#!/usr/bin/env bash
# Empaqueta mac/ y windows/ en web/downloads/ para retro76.cl
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=../scripts/resolve-project-root.sh
source "$SCRIPT_DIR/../scripts/resolve-project-root.sh"
ROOT="$(resolve_project_root)"
DL="$ROOT/web/downloads"
export COPYFILE_DISABLE=1

mkdir -p "$DL"

cd "$SCRIPT_DIR/mac"
zip -r -y "$DL/Retro76-Mac.zip" . -x "*.DS_Store" -x "*.log" >/dev/null

cd "$SCRIPT_DIR/windows"
zip -r -y "$DL/Retro76-Windows.zip" . -x "*.DS_Store" -x "*.log" >/dev/null

ls -lh "$DL/Retro76-Mac.zip" "$DL/Retro76-Windows.zip"
echo "OK → web/downloads/ listo para upload-client-downloads.sh"
