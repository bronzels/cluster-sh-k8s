
action=$1

ansible slave -i /etc/ansible/hosts-hadoop -m shell -a"/app/home/hadoop/zookeeper/bin/zkServer.sh $action"
