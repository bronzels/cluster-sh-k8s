now=`date --date='0 days ago' "+%Y-%m-%d_%H:%M:%S"`

kubectl get pod -n flow | awk '{print $1}' | grep worker | xargs -I CNAME  sh -c "kubectl exec -n flow CNAME -- python /usr/local/airflow/dags/py/fm/util/watch_consul_config_2_kafka.py 2> /usr/local/airflow/dags/watch_consul_config_2_kafka_stderr_${now}.log > /usr/local/airflow/dags/watch_consul_config_2_kafka_stdout_${now}.log &"
