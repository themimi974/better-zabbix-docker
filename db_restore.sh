#!/bin/sh
# RUN AFTER UPGRADING POSTGRES IMAGE.

docker compose up -d postgres
cat pgdump.sql | docker compose exec -T postgres psql -U zabbix -d zabbix
docker compose down