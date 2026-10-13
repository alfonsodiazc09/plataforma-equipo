#!/usr/bin/env bash
# Instalación desde cero en una máquina nueva.
source "$(dirname "$0")/common.sh"
cd "$ROOT"

[ -f .env ] || { cp .env.example .env; echo "Creé .env desde .env.example: llénalo si tu plugin necesita llaves."; }

python3 -m venv "$VENV"
"$VENV/bin/pip" install --upgrade pip
"$VENV/bin/pip" install -r requirements.txt

apply_config
apply_plugins
apply_mounts
"$TUTOR" dev launch --non-interactive

echo
echo "Listo. LMS: http://local.openedx.io:8000  Studio: http://studio.local.openedx.io:8001"
echo "Crea tu admin con: make admin"
