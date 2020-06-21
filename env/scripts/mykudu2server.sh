op=$1
echo "op:${op}"

if [ $op == "start" ]; then
echo "master"
nohup  ~/kudu2/usr/local/sbin/kudu-master --flagfile ~/kudu2/config/master.gflagfile > ~/kudu2/logs/std_out.log 2>&1 &
echo "slaves"
ansible slave -i /etc/ansible/hosts-hadoop -m shell -a"~/scripts/mykudu2_tserver.sh"
else
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"~/scripts/killport.sh 7152"
ansible all -i /etc/ansible/hosts-hadoop -m shell -a"netstat -nlap|grep 7152"
fi

