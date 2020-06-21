. ~/venvs/airflow/bin/activate
now=`date --date='0 days ago' "+%Y-%m-%d_%H:%M:%S"`
python ~/venvs/airflow/dags/py/fm/util/watch_consul_brokerid_timezone_config_2_kafka.py 2> ~/fm/python_watch_broker_timezone_stderr_${now}.log > ~/fm/python_watch_broker_timezone_stdout_${now}.log &
