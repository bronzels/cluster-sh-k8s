#在webui里手工把除hosts以外可删除组件，按照依赖关系全部stop/delete
ansible allcdh -m shell -a"systemctl stop cloudera-scm-agent"
systemctl stop cloudera-scm-server

ansible allcdh -m shell -a"apt-get remove -y cloudera-manager-daemons cloudera-manager-agent cloudera-manager-server"

ansible allcdh -m shell -a"umount cm_processes"
ansible allcdh -m shell -a"umount /var/run/cloudera-scm-agent/process"
ansible allcdh -m shell -a"rm -rf /usr/share/cmf /var/lib/cloudera* /var/log/cloudera* /var/run/cloudera*"
ansible allcdh -m shell -a"rm -rf /tmp/.scmpreparenode.lock"
ansible allcdh -m shell -a"rm -rf /var/lib/hadoop* /var/lib/navigator /var/lib/zookeeper /var/lib/hbase /var/lib/sqoop /var/lib/spark /var/lib/kudu"
ansible allcdh -m shell -a"rm -rf /app/*"
ansible allcdh -m shell -a"rm -rf /opt/cloudera"

docker stop `docker ps  |grep mysql_cdh | awk '{print $1}'`
docker rm `docker ps -a |grep mysql_cdh | awk '{print $1}'`

ansible allcdh -m shell -a"rm -f /etc/apt/sources.list.d/cloudera-manager.list"
ansible allcdh -m shell -a"rm -f /var/cache/apt/archives/cloudera-manager*"

mv ~/cdh ~/cdh.6.3.2

