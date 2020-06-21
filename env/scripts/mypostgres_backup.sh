#!/bin/bash
prefix=$1

export PGPASSWORD=postgres
mkdir /app/backup/postgres${prefix}
pg_dump -h 10.1.0.11 -U postgres bd${prefix}  -t copytrading.t_trades_lvd > /app/backup/postgres${prefix}/t_trades_lvd.sql