#!/bin/bash
# =====================================================================
# Seed inicial del contenedor: normaliza db/02_load.sql con la ruta /seed
# y lo ejecuta con el cliente mysql interno ( --local-infile=1 ).
# Lo corre automáticamente docker-entrypoint-initdb.d en el 1er arranque.
# Idempotente vía INSERT IGNORE; verifica conteos y reporta "seed OK".
# =====================================================================
set -euo pipefail

: "${MYSQL_ROOT_PASSWORD:?requiere MYSQL_ROOT_PASSWORD}"
DB="${MYSQL_DATABASE:-sepomex}"
CSV="/seed/codigos_postales_cdmx.csv"
SQL_SRC="/seed-sql/02_load.sql"

# 01_schema.sql ya corrió (el entrypoint ejecuta 01_* antes que 02_*).
# 02_load.sql se monta en /seed-sql (NO en entrypoint) para sustituirle
# la ruta <RUTA_CSV> antes de ejecutarlo.
if [ ! -f "$CSV" ]; then
  echo "seed ERROR: no existe $CSV (¿montaste ./data en /seed?)" >&2
  exit 1
fi
if [ ! -f "$SQL_SRC" ]; then
  echo "seed ERROR: no existe $SQL_SRC (¿montaste ./db/02_load.sql en /seed-sql?)" >&2
  exit 1
fi

TMP="$(mktemp /tmp/02_load.XXXXXX.sql)"
sed "s|<RUTA_CSV>|$CSV|" "$SQL_SRC" > "$TMP"

mysql --protocol=socket --local-infile=1 -uroot -p"$MYSQL_ROOT_PASSWORD" "$DB" < "$TMP"
rm -f "$TMP"
echo "seed OK: $DB cargado desde $CSV"
