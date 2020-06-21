#!/bin/bash
echo "!!!Usage: $0 <driver-memory(g)> <executor-memory(g)> <executor-cores>..."
echo driver-memory:$1
echo executor-memory:$2
echo executor-cores:$3
echo other args:$4

start_time=$(date "+%Y-%m-%d %H:%M:%S")
echo "${start_time}"

#spark-sql --conf spark.default.parallelism=20 --conf spark.sql.autoBroadcastJoinThreshold=2000000 --master yarn --deploy-mode client --driver-memory "$1"g --executor-memory "$2"g --executor-cores "$3" -e "show tables";
#spark-sql --conf spark.default.parallelism=20 --conf spark.sql.autoBroadcastJoinThreshold=2000000 --master yarn --deploy-mode client --driver-memory "$1"g --executor-memory "$2"g --executor-cores "$3" -e "select count(*) from t_users;";
#spark-sql --conf spark.default.parallelism=20 --conf spark.sql.autoBroadcastJoinThreshold=2000000 --master yarn --deploy-mode client --driver-memory "$1"g --executor-memory "$2"g --executor-cores "$3" -e "select count(*) from user_accounts;";
#spark-sql --conf spark.default.parallelism=20 --conf spark.sql.autoBroadcastJoinThreshold=2000000 --master yarn --driver-memory "$1"g --executor-memory "$2"g --executor-cores "$3" -e "select count(*) from t_trades;";

#spark-sql --conf spark.default.parallelism=20 --conf spark.sql.autoBroadcastJoinThreshold=2000000 --master yarn --deploy-mode client --driver-memory "$1"g --executor-memory "$2"g --executor-cores "$3" -e "select count(distinct account,brokerid) from t_users;";
#spark-sql --conf spark.default.parallelism=20 --conf spark.sql.autoBroadcastJoinThreshold=2000000 --master yarn --deploy-mode client --driver-memory "$1"g --executor-memory "$2"g --executor-cores "$3" -e "select count(distinct mt4_account,broker_id)  from user_accounts;";
spark-sql --conf spark.default.parallelism=20 --conf spark.sql.autoBroadcastJoinThreshold=2000000 --master yarn --driver-memory "$1"g --executor-memory "$2"g --executor-cores "$3" -e "select count(distinct account,brokerid,tradeid) from t_trades;";

end_time=$(date "+%Y-%m-%d %H:%M:%S")
echo "${end_time}"
