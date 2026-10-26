#!/usr/bin/env bash
# Respaldo de usuarios, cursos y progreso (MySQL + MongoDB), del CMS (cursos a la venta, precios
# y ventas) y de los videos subidos desde Campus en backups/AAAA-MM-DD_HHMM/.
source "$(dirname "$0")/common.sh"
cd "$ROOT"
OUT="backups/$(date +%Y-%m-%d_%H%M)"
mkdir -p "$OUT"
"$TUTOR" dev start -d mysql mongodb
DBS=openedx
# Una instalación sin el CMS (por ejemplo, la vieja de TUTOR_ROOT_OVERRIDE) no tiene su base.
CMS_DB="$("$TUTOR" config printvalue CAMPUS_CMS_MYSQL_DATABASE 2>/dev/null || true)"
if [ -n "$CMS_DB" ] && "$TUTOR" dev dc exec -T mysql sh -c "mysql -uroot -p\"\$MYSQL_ROOT_PASSWORD\" -e 'USE $CMS_DB'" 2>/dev/null; then
  DBS="$DBS $CMS_DB"
fi
"$TUTOR" dev dc exec -T mysql sh -c "mysqldump -uroot -p\"\$MYSQL_ROOT_PASSWORD\" --databases $DBS" > "$OUT/mysql.sql"
"$TUTOR" dev dc exec -T mongodb mongodump --db openedx --archive > "$OUT/mongodb.archive"
# Videos subidos desde /admin de Campus: viven en su disco, no en Open edX.
VIDEOS=src/front-campus/.data/videos
[ -d "$VIDEOS" ] && tar -czf "$OUT/videos.tar.gz" -C "$VIDEOS" .
echo "Respaldo en $OUT"
