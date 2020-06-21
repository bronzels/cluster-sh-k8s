#!/bin/bash
if [ $1 == "start" ]; then
for((i=1;i<=3;i++));  
do   
ssh pro-hbase02 ~/redis/bin/redis-server ~/redis/redis_cluster/700${i}/redis.conf
done

for((i=4;i<=6;i++));  
do   
ssh pro-hbase03 ~/redis/bin/redis-server ~/redis/redis_cluster/700${i}/redis.conf
done

for((i=7;i<=9;i++));  
do   
ssh pro-hbase04 ~/redis/bin/redis-server ~/redis/redis_cluster/700${i}/redis.conf
done

else
ansible -i /etc/ansible/hosts-hadoop slave -m shell -a". ~/.bash_profile;killname.sh redis-server"
fi

ansible -i /etc/ansible/hosts-hadoop slave -m shell -a"ps -ef | grep redis"
ansible -i /etc/ansible/hosts-hadoop slave -m shell -a"netstat -tuplan | grep redis"

