#!/usr/bin/env bash
# Trae los cambios del equipo y los aplica. Se corre después de cada git pull.
source "$(dirname "$0")/common.sh"
cd "$ROOT"

git pull --rebase --autostash || echo "Aviso: no se pudo hacer git pull; sigo con lo que hay local." >&2
git submodule update --init --recursive 2>/dev/null || true

"$VENV/bin/pip" install -r requirements.txt
apply_config
apply_plugins
apply_mounts
"$TUTOR" images build openedx-dev
"$TUTOR" dev start -d
"$TUTOR" dev do init
"$TUTOR" dev restart
echo "Actualizado."
