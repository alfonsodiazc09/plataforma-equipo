#!/usr/bin/env bash
# Variables comunes: cada repo tiene su propio Tutor, así dos proyectos nunca se mezclan.
set -eo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# TUTOR_ROOT_OVERRIDE permite apuntar a otra instalación (por ejemplo, para respaldar la anterior).
export TUTOR_ROOT="${TUTOR_ROOT_OVERRIDE:-$ROOT/.tutor}"
export TUTOR_PLUGINS_ROOT="$ROOT/tutor-plugins"
VENV="$ROOT/venv"
TUTOR="$VENV/bin/tutor"

# Lee un archivo CLAVE=valor ignorando comentarios y líneas vacías.
# También quita los comentarios al final de la línea (un # precedido de espacio), como en el README.
read_kv() {
  [ -f "$1" ] || return 0
  grep -vE '^[[:space:]]*(#|$)' "$1" | sed -E 's/[[:space:]]+#.*$//; s/[[:space:]]*$//' || true
}

read_list() {
  [ -f "$1" ] || return 0
  grep -vE '^[[:space:]]*(#|$)' "$1" | sed 's/[[:space:]]*$//' || true
}

apply_config() {
  local args=()
  while IFS= read -r line; do args+=(--set "$line"); done < <(read_kv "$ROOT/config/tutor.env")
  while IFS= read -r line; do args+=(--set "$line"); done < <(read_kv "$ROOT/.env")
  "$TUTOR" config save "${args[@]}"
}

apply_plugins() {
  # Deja activos exactamente los plugins de config/plugins.txt más los de tutor-plugins/.
  local wanted=()
  while IFS= read -r p; do wanted+=("$p"); done < <(read_list "$ROOT/config/plugins.txt")
  for f in "$TUTOR_PLUGINS_ROOT"/*.py "$TUTOR_PLUGINS_ROOT"/*.yml; do
    [ -e "$f" ] || continue
    wanted+=("$(basename "${f%.*}")")
  done
  local enabled
  enabled="$("$TUTOR" plugins list | awk '/enabled/ {print $1}')"
  for p in $enabled; do
    if ! printf '%s\n' "${wanted[@]}" | grep -qx "$p"; then
      "$TUTOR" plugins disable "$p"
    fi
  done
  [ ${#wanted[@]} -eq 0 ] || "$TUTOR" plugins enable "${wanted[@]}"
}

apply_mounts() {
  # Reemplaza la lista completa de montajes por la de config/mounts.txt.
  local items=()
  while IFS= read -r m; do
    if [ -d "$ROOT/$m" ]; then
      items+=("\"$ROOT/$m\"")
    else
      echo "Aviso: no existe $m (¿falta clonarlo?). Se omite." >&2
    fi
  done < <(read_list "$ROOT/config/mounts.txt")
  local joined
  joined="$(IFS=,; echo "${items[*]:-}")"
  "$TUTOR" config save --set "MOUNTS=[$joined]"
}
