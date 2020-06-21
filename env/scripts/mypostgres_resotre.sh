#!/bin/bash
export PGPASSWORD=postgres
psql -h 10.0.0.51 -U postgres -d bd${prefix} -f /app/backup/postgres${prefix}/t_trades_lvd.sql