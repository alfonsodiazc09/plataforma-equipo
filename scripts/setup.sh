#!/usr/bin/env bash
# Instalación desde cero en una máquina nueva.
source "$(dirname "$0")/common.sh"
cd "$ROOT"

[ -f .env ] || { cp .env.example .env; echo "Creé .env desde .env.example: llénalo si tu plugin necesita llaves."; }

# En macOS `python3` suele ser el 3.9 de Apple: se prefiere un Python más nuevo si existe.
PYTHON="${PYTHON:-}"
if [ -z "$PYTHON" ]; then
  for p in python3.13 python3.12 python3.11 python3.10 python3; do
    if command -v "$p" >/dev/null; then PYTHON="$p"; break; fi
  done
fi
# Si el venv se creó con otro Python (o quedó a medias sin bin/tutor), se crea de nuevo.
if [ -x "$VENV/bin/python" ] && [ -x "$VENV/bin/tutor" ] \
  && [ "$("$VENV/bin/python" -c 'import sys; print(sys.version_info[:2])')" = "$("$PYTHON" -c 'import sys; print(sys.version_info[:2])')" ]; then
  :
else
  rm -rf "$VENV"
  "$PYTHON" -m venv "$VENV"
fi
"$VENV/bin/pip" install --upgrade pip
"$VENV/bin/pip" install -r requirements.txt

apply_config
apply_plugins
apply_mounts
"$TUTOR" dev launch --non-interactive

echo
echo "Listo. LMS: http://local.openedx.io:8000  Studio: http://studio.local.openedx.io:8001"
echo "CMS: http://campus-cms.local.openedx.io:8010/api/health/"
echo "Crea tu admin con: make admin, y dale acceso a /admin de Campus con: make contador USER_NAME=admin"
