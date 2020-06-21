#!/bin/bash
ns=$1
echo "ns:${ns}"
bg_date=$2
echo "bg_date:${bg_date}"

for((i=0;i<=5;i++));
do
kubectl -n {ns} exec -ti redis-server-${i} -- kill -9 $(lsof -i:9221 |awk '{print $2}' | tail -n 2)
kubectl -n {ns} exec -ti redis-server-${i} -- cp -r /app/pika/dump/${bg_date}/* /app/pika/db/
kubectl -n {ns} exec -ti redis-server-${i} -- nohup /pika/output/bin/pika -c /pika/conf/pika.conf >/dev/null 2>&1 &
done