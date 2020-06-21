. ~/venvs/airflow/bin/activate
now=`date --date='0 days ago' "+%Y-%m-%d_%H:%M:%S"`
python ~/venvs/airflow/dags/py/fm/util/watch_consul_config_2_kafka.py 2> ~/fm/watch_consul_config_2_kafka_stderr_${now}.log > ~/fm/watch_consul_config_2_kafka_stdout_${now}.log &
