ansible allcdh -m shell -a"apt-get remove -y cloudera-manager-daemons cloudera-manager-agent cloudera-manager-server"

ansible allcdh -m shell -a"umount cm_processes"
ansible allcdh -m shell -a"umount /var/run/cloudera-scm-agent/process"
ansible allcdh -m shell -a"rm -rf /usr/share/cmf /var/lib/cloudera* /var/log/cloudera* /var/run/cloudera*"
ansible allcdh -m shell -a"rm -rf /tmp/.scmpreparenode.lock"
ansible allcdh -m shell -a"rm -rf /var/lib/hadoop* /var/lib/navigator /var/lib/zookeeper /var/lib/spark /var/lib/kudu"
ansible allcdh -m shell -a"rm -rf /app/*"
ansible allcdh -m shell -a"rm -rf /opt/cloudera"

docker ps|grep mysql
docker stop 0e3872ad5edc
docker rm 0e3872ad5edc

ansible allcdh -m shell -a"rm -f /etc/apt/sources.list.d/cloudera-manager.list"
ansible allcdh -m shell -a"/var/cache/apt/archives/cloudera-manager*"
ansible allcdh -m shell -a"rm -rf /opt/cloudera"
#ansible allcdh -m shell -a""

#mv ~/cdh/deb.6.3.2 ~/cdh/deb
mv ~/cdh/deb ~/cdh/deb.6.3.2
#mv ~/cdh/parcel.6.3.2 ~/cdh/parcel
mv ~/cdh/parcel ~/cdh/parcel.6.3.2

