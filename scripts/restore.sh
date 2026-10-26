#!/usr/bin/env bash
# Restaura un respaldo: make restore BACKUP=backups/2026-10-13_1500
source "$(dirname "$0")/common.sh"
cd "$ROOT"
DIR="${1:?Indica la carpeta: make restore BACKUP=backups/...}"
read -r -p "Esto reemplaza los datos actuales de esta máquina con $DIR. ¿Continuar? [s/N] " ok
[ "$ok" = "s" ] || { echo "Cancelado."; exit 1; }
CMS_DB="$("$TUTOR" config printvalue CAMPUS_CMS_MYSQL_DATABASE)"
DBS=openedx
# Los respaldos anteriores al CMS no traen su base: en ese caso se deja la actual.
grep -q "^CREATE DATABASE .*\`$CMS_DB\`" "$DIR/mysql.sql" && DBS="$DBS $CMS_DB"
"$TUTOR" dev start -d mysql mongodb
# Se borran las bases completas para que no queden tablas que el respaldo no conoce;
# después `do init` vuelve a crear las de los plugins nuevos.
for db in $DBS; do
  "$TUTOR" dev dc exec -T mysql sh -c "mysql -uroot -p\"\$MYSQL_ROOT_PASSWORD\" -e 'DROP DATABASE IF EXISTS $db'"
done
"$TUTOR" dev dc exec -T mysql sh -c 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD"' < "$DIR/mysql.sql"
"$TUTOR" dev dc exec -T mongodb mongorestore --drop --archive < "$DIR/mongodb.archive"
"$TUTOR" dev do init
"$TUTOR" dev restart
echo "Restaurado."
