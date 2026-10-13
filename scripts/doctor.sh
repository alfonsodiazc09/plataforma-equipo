#!/usr/bin/env bash
# Muestra el estado para comparar entre máquinas del equipo.
source "$(dirname "$0")/common.sh"
cd "$ROOT"
echo "== Repo";      git log -1 --oneline 2>/dev/null || echo "(sin git)"
echo "== Tutor";     "$TUTOR" --version
echo "== Raíz";      echo "$TUTOR_ROOT"
echo "== Plugins";   "$TUTOR" plugins list | grep -E 'enabled' || true
echo "== Montajes";  "$TUTOR" mounts list
echo "== Docker";    docker system df
