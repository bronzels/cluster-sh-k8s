#!/bin/bash
ns=$1

for((i=0;i<=5;i++));
do
kubectl -n {ns} exec -ti redis-server-${i} -- redis-cli -h localhost -p 9221 bgsave
done