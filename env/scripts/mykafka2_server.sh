action=$1

if [ $1 == "start" ]; then
ansible slave -i /etc/ansible/hosts-hadoop -m shell -a"~/kafka/bin/kafka-server-start.sh -daemon ~/kafka/config/server2.properties"
fi

if [ $1 == "stop" ]; then
ansible -i /etc/ansible/hosts-hadoop slave -m shell -a". ~/.bash_profile;killport.sh 9492"
fi

if [ $1 == "status" ]; then
ansible -i /etc/ansible/hosts-hadoop slave -m shell -a" lsof -i:9492"
fi
