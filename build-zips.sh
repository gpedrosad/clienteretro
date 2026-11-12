#!/usr/bin/env bash
# Publica el cliente: sprites de serverrepo -> mac/ y windows/, carpeta del auto-updater de la web y zips de
# descarga (binario + lanzador + data.zip). Todo lo hace el script de serverrepo; ver su
# docs/CLIENT_UPDATER_RETRO76.md.
set -euo pipefail
SERVERREPO="${SERVERREPO:-$HOME/apps/serverrepo}"
exec python3 "$SERVERREPO/scripts/client-rme/publish_client.py" --client "$(cd "$(dirname "$0")" && pwd)" "$@"
