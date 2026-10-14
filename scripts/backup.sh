#!/usr/bin/env bash
# Respaldo de usuarios, cursos y progreso (MySQL + MongoDB) en backups/AAAA-MM-DD_HHMM/.
source "$(dirname "$0")/common.sh"
cd "$ROOT"
OUT="backups/$(date +%Y-%m-%d_%H%M)"
mkdir -p "$OUT"
"$TUTOR" dev start -d mysql mongodb
"$TUTOR" dev dc exec -T mysql sh -c 'mysqldump -uroot -p"$MYSQL_ROOT_PASSWORD" --databases openedx' > "$OUT/mysql.sql"
"$TUTOR" dev dc exec -T mongodb mongodump --db openedx --archive > "$OUT/mongodb.archive"
echo "Respaldo en $OUT"
