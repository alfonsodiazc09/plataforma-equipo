#!/usr/bin/env bash
# Aplica config/tutor.env y .env sin reconstruir nada (por ejemplo, después de cambiar una llave).
source "$(dirname "$0")/common.sh"
cd "$ROOT"
apply_config
"$TUTOR" dev restart lms
