#!/usr/bin/env bash
# Restaura un respaldo: make restore BACKUP=backups/2026-10-13_1500
source "$(dirname "$0")/common.sh"
cd "$ROOT"
DIR="${1:?Indica la carpeta: make restore BACKUP=backups/...}"
read -r -p "Esto reemplaza los datos actuales de esta máquina con $DIR. ¿Continuar? [s/N] " ok
[ "$ok" = "s" ] || { echo "Cancelado."; exit 1; }
"$TUTOR" dev start -d mysql mongodb
"$TUTOR" dev dc exec -T mysql sh -c 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD"' < "$DIR/mysql.sql"
"$TUTOR" dev dc exec -T mongodb mongorestore --drop --archive < "$DIR/mongodb.archive"
"$TUTOR" dev do init
"$TUTOR" dev restart
echo "Restaurado."
