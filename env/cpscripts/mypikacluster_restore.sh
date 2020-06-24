#!/bin/bash
ns=$1
echo "ns:${ns}"
#bg_date=$2
#echo "bg_date:${bg_date}"

. ${HOME}/scripts/k8s_funcs.sh

for((i=0;i<=5;i++));
do
bg_date=`kubectl -n {ns} exec -ti redis-server-${i} -- ls -rt /data/dump  | awk 'END {print}'`
#kubectl -n ${ns} exec -ti redis-server-${i} -- kill -9 $(lsof -i:9221 |awk '{print $2}' | tail -n 2)
kubectl -n ${ns} exec -ti redis-server-${i} -- cp -r /data/dump/${bg_date}/* /data/db/
#kubectl -n ${ns} exec -ti redis-server-${i} -- nohup /pika/output/bin/pika -c /pika/conf/pika.conf >/dev/null 2>&1 &
kubectl get pod redis-server-${i} -n ${ns} -o yaml | kubectl replace --force -f -
done

#${HOME}/scripts/mycodis-cp-op.sh restart ${ns}