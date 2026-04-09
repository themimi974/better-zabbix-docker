#!/bin/sh
set -e
# RUN BEFORE UPGRADING POSTGRES IMAGE.
docker compose down

docker compose up -d postgres
sleep 5
docker compose exec postgres pg_dumpall -U zabbix > pgdump.sql
echo "Dump created: $(wc -c < pgdump.sql) bytes"
docker compose down