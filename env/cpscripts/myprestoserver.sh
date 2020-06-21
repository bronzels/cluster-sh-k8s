#!/bin/bash
if [ $1 == "start" ]; then
	echo "!!!master"
/app/hadoop/presto-server/bin/launcher start
ansible -i /etc/ansible/hosts-hadoop slave -m shell -a"/app/hadoop/presto-server/bin/launcher start"
fi
if [ $1 == "stop" ]; then
/app/hadoop/presto-server/bin/launcher stop
ansible -i /etc/ansible/hosts-hadoop slave -m shell -a"/app/hadoop/presto-server/bin/launcher stop"
fi
if [ $1 == "status" ]; then
/app/hadoop/presto-server/bin/launcher status
ansible -i /etc/ansible/hosts-hadoop slave -m shell -a"/app/hadoop/presto-server/bin/launcher status"
fi

