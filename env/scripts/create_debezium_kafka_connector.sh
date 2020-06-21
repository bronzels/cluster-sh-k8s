#!/bin/bash

curl -X DELETE localhost:8083/connectors/betamysql0005-debezium-connector
curl -i -X DELETE -H "Accept:application/json" -H "Content-Type:application/json" localhost:8083/connectors/betapostgres_0_0_0_16_8_22_21_v3_lvd-debezium-connector

/var/lib/hadoop-hdfs/scripts/mykafka-topics-del.sh betamysql0001*

curl -X DELETE beta-hbase01:8083/connectors/betamysql_0_0_0_17_8_27_20_lvd-debezium-connector

curl -X DELETE beta-hbase01:8083/connectors/betamysql_0_0_0_20_9_2_0_lvd-deb-connector
curl -X DELETE beta-hbase01:9084/connectors/betamysql_0_0_0_17_8_27_20_lvd-debezium-connector


tasks
curl -X GET -H "Accept:application/json" -H "Content-Type:application/json" beta-hbase01:8083/connectors/betamysql_0_0_0_21_9_4_21_lvd_v1-deb-connector/status

curl -i -X DELETE -H "Accept:application/json" -H "Content-Type:application/json" localhost:9084/connectors/betamysql_0_0_0_16_8_22_21-debezium-connector

curl -X POST localhost:9084/connectors/betapostgres_0_0_0_16_8_22_21_v2_lvd-debezium-connector/restart
curl -X PUT localhost:9084/connectors/betapostgres_0_0_0_16_8_22_21_v2_lvd-debezium-connector/resume
curl -X PUT beta-hbase01:9084/connectors/betapostgres_0_0_0_16_8_22_21_v2_lvd-deb-connector/pause

/var/lib/hadoop-hdfs/scripts/mykafka-topics-del.sh fmkcplugin_v1-beta-dbhistory.beta-debezium


curl -X POST localhost:8083/connectors/betamysql_0_0_0_20_9_2_0_lvd-debezium-connector/restart

curl -X PUT beta-hbase01:8083/connectors/betamysql_0_0_0_17_8_27_20_lvd-deb-connector/pause
curl -X DELETE beta-hbase01:8083/connectors/betamysql_0_0_0_17_8_27_20_lvd-debezium-connector

betamysql_0_0_0_16_8_25_16_lvd_v4.copytrading.t_trades_lvd
betamysql_0_0_0_16_8_25_16_lvd_v5.copytrading.t_trades_lvd
betamysql_0_0_0_16_8_25_16_lvd_v6.copytrading.t_trades_lvd

curl -X PUT pro-hbase01:8083/connectors/str_0_1_0_0_9_7_15-deb-connector/pause
curl -X DELETE beta-hbase01:8083/connectors/betamysql_0_0_0_16_8_26_15_lvd_v3-debezium-connector
PUT


curl -i -X POST -H "Accept:application/json" -H "Content-Type:application/json" http://10.1.0.11:8083/connectors/ -d '
{
    "name": "betamysql_0_0_0_15_8_21_16-debezium-connector",
    "config": {
    "connector.class": "io.debezium.connector.mysql.MySqlConnector",
    "tasks.max": "1",
    "snapshot.mode": "schema_only",
    "database.hostname": "10.1.0.7",
    "database.port": "3326",
    "database.user": "fmbetadb002",
    "database.password": "31Bawd0c5GEq",
    "database.server.name": "betamysql_0_0_0_15_8_21_16",
    "database.whitelist":"copytrading,account",
    "table.whitelist": "copytrading.t_trades,copytrading.t_users,account.user_accounts,copytrading.t_followorder",
    "snapshot.locking.mode": "none",
    "database.history.kafka.bootstrap.servers": "beta-hbase02:9092,beta-hbase03:9092,beta-hbase04:9092",
    "database.history.kafka.topic": "betamysql_0_0_0_15_8_21_16-dbhistory.beta-debezium",
    "database.history.store.only.monitored.tables.ddl":"true",
    "database.history.kafka.recovery.poll.interval.ms":"500",
    "include.schema.changes": "false",
    "databasei.history.skip.unparseable.ddl": "true",
    "database.history.store.only.monitored.tables.ddl": "true",
    "inconsistent.schema.handling.mode": "warn",
    "transforms": "route",
    "transforms.route.type": "com.fm.data.fmkcplugin.fm.FMMysqlDebTopicsRouteTransformation"
    }
}
'


curl -i -X POST -H "Accept:application/json" -H "Content-Type:application/json" http://pro-hbase02:8083/connectors/ -d '
{
    "name": "probetamysql-debezium-connector",
    "config": {
    "connector.class": "io.debezium.connector.mysql.MySqlConnector",
    "tasks.max": "1",
    "snapshot.mode": "schema_only",
    "database.hostname": "10.1.0.7",
    "database.port": "3326",
    "database.user": "fmbetadb002",
    "database.password": "31Bawd0c5GEq",
    "database.server.name": "probetamysql",
    "database.whitelist":"copytrading",
    "table.whitelist": "copytrading.t_trades",
    "snapshot.locking.mode": "none",
    "database.history.kafka.bootstrap.servers": "pro-hbase02:9092,pro-hbase03:9092,pro-hbase04:9092",
    "database.history.kafka.topic": "probetamysql-dbhistory.probetamysql-debezium",
    "database.history.store.only.monitored.tables.ddl":"true",
    "database.history.kafka.recovery.poll.interval.ms":"500",
    "include.schema.changes": "false",
    "databasei.history.skip.unparseable.ddl": "true",
    "database.history.store.only.monitored.tables.ddl": "true",
    "inconsistent.schema.handling.mode": "warn"
    }
}
'

curl -i -X POST -H "Accept:application/json" -H "Content-Type:application/json" http://pro-hbase02:8083/connectors/ -d '
{
    "name": "fmmysqldebug-debezium-connector",
    "config": {
    "connector.class": "io.debezium.connector.mysql.MySqlConnector",
    "tasks.max": "1",
    "snapshot.mode": "schema_only",
    "database.hostname": "rm-wz905j9253s6l04l6.mysql.rds.aliyuncs.com",
    "database.port": "3326",
    "database.user": "fmbetadb002",
    "database.password": "31Bawd0c5GEq",
    "database.server.name": "fmmysqldebug",
    "database.whitelist":"copytrading,account",
    "table.whitelist": "copytrading.t_trades,copytrading.t_followorder,account.user_accounts",
    "snapshot.locking.mode": "none",
    "database.history.kafka.bootstrap.servers": "pro-hbase02:9092,pro-hbase03:9092,pro-hbase04:9092",
    "database.history.kafka.topic": "fmmysqldebug-dbhistory.beta-debezium",
    "database.history.store.only.monitored.tables.ddl":"true",
    "database.history.kafka.recovery.poll.interval.ms":"500",
    "include.schema.changes": "false",
    "databasei.history.skip.unparseable.ddl": "true",
    "database.history.store.only.monitored.tables.ddl": "true",
    "inconsistent.schema.handling.mode": "warn"
    }
}
'

nohup connect-distributed ~/confluent/config/connect-distributed-postgres.properties 2> ~/confluent/logs/connect-distributed_postgres_stderr.log > ~/confluent/logs/connect-distributed_postgres_stdout.log &
tailf ~/confluent/logs/connect-distributed_postgres_stdout.log

curl -i -X POST -H "Accept:application/json" -H "Content-Type:application/json" http://pro-hbase01:8083/connectors/ -d '
        {
            "name": "betamysql_0_0_0_18_8_28_21_lvd_v8-debezium-connector",
            "config": {
                "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
                "slot.drop_on_stop": "true",
                "snapshot.mode": "never",
                "database.hostname": "10.0.0.51",
                "database.port": "5432",
                "database.user": "postgres",
                "database.password": "postgres",
                "database.dbname" : "bd",
                "database.server.name": "betamysql_0_0_0_18_8_28_21_lvd_v8",
                "schema.whitelist": "copytrading",
                "table.whitelist": "copytrading.t_trades_lvd",
                "transforms": "route",
                "transforms.route.type": "com.fm.data.fmkcplugin.fm.FMMysqlDebTopicsRouteTransformation"
            }
        }'


curl -X PUT localhost:8083/connectors/jsd_pa_test_v1-debezium-connector/pause

curl -i -X DELETE -H "Accept:application/json" -H "Content-Type:application/json" localhost:8083/connectors/jsd_p_test_v3-debezium-connector

./mykafka-topics-del.sh jsd_test_v8*
ansible slave -i /etc/ansible/hosts-hadoop -m shell -a"rm -rf /app/kafka/log/jsd_test_v7*"

nohup connect-distributed ~/confluent/config/connect-distributed.properties 2> ~/confluent/logs/connect-distributed_stderr.log > ~/confluent/logs/connect-distributed_stdout.log &