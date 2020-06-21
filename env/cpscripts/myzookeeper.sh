#!/bin/bash
ansible slave -i /etc/ansible/hosts-hadoop -m shell -a"cd $ZOOKEEPER_HOME;zkServer.sh $1"
