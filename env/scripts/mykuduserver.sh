op=$1
echo "op:${op}"

if [ $op == "start" ]; then
echo "master"
nohup  ~/kudu/usr/local/sbin/kudu-master --flagfile ~/kudu/config/master.gflagfile > ~/kudu/logs/std_out.log 2>&1 &
echo "slaves"
ansible slave -i /etc/ansible/hosts-hadoop -m shell -a"~/scripts/mykudu_tserver.sh"
else
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"~/scripts/killport.sh 7052"
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"netstat -nlap|grep 7052"
fi

