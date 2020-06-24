#root

cd

ansible allcdh -m shell -a"apt-get install -yq cloudera-manager-daemons cloudera-manager-agent cloudera-manager-server"

/opt/cloudera/cm/schema/scm_prepare_database.sh mysql scm scm scm
/opt/cloudera/cm/schema/scm_prepare_database.sh mysql amon amon amon
/opt/cloudera/cm/schema/scm_prepare_database.sh mysql rman rman rman
/opt/cloudera/cm/schema/scm_prepare_database.sh mysql hue hue hue
/opt/cloudera/cm/schema/scm_prepare_database.sh mysql hive hive hive
/opt/cloudera/cm/schema/scm_prepare_database.sh mysql sentry sentry sentry
/opt/cloudera/cm/schema/scm_prepare_database.sh mysql nav nav nav
/opt/cloudera/cm/schema/scm_prepare_database.sh mysql navms navms navms
/opt/cloudera/cm/schema/scm_prepare_database.sh mysql oozie oozie oozie

file=/etc/cloudera-scm-agent/config.ini
cp ${file} ${file}.bk
sed -i 's@server_host=localhost@server_host=hk-prod-bigdata-slave-0-234@g' ${file}
ansible slavecdh -m copy -a"src=/etc/cloudera-scm-agent/config.ini dest=/etc/cloudera-scm-agent"

systemctl start cloudera-scm-server
tail -f /var/log/cloudera-scm-server/cloudera-scm-server.log
#会提示无法下载sqoop 404 URI，重新stop/start就好了
#systemctl restart cloudera-scm-server

ansible allcdh -m shell -a"sysctl vm.swappiness=10"
ansible allcdh -m shell -a"echo 'vm.swappiness=10'>> /etc/sysctl.conf"

#each
#写在重装如果slave log提示错误
  #kill -9 $(pgrep -f supervisord)
ansible allcdh -m shell -a"systemctl start cloudera-scm-agent"
ansible allcdh -m shell -a"tail -100 /var/log/cloudera-scm-agent/cloudera-scm-agent.log"

ansible allcdh -m shell -a"systemctl status cloudera-scm-agent"

curl http://slave01:7180/
:<<EOF
访问cloudera-manager
浏览器输入http://slave01:7180/
用户/密码：admin/admin
按照向导搭建集群。
有问题查看日志解决
EOF

cat << \EOF >> /root/.bashrc
export HADOOP_HOME=/opt/cloudera/parcels/CDH/lib/hadoop
export HADOOP_CONF_DIR=/etc/hadoop/conf

export hadoopCDH="1"

export HADOOP_COMMON_HOME=/opt/cloudera/parcels/CDH/lib/hadoop
export HADOOP_HDFS_HOME=/opt/cloudera/parcels/CDH/lib/hadoop-hdfs
export YARN_HOME=/opt/cloudera/parcels/CDH/lib/hadoop-yarn
export HADOOP_MAPRED_HOME=/opt/cloudera/parcels/CDH/lib/hadoop-mapreduce

export ZOOKEEPER_HOME=/opt/cloudera/parcels/CDH/lib/zookeeper
export HCAT_HOME=/opt/cloudera/parcels/CDH/lib/hive-hcatalog
export HIVE_HOME=/opt/cloudera/parcels/CDH/lib/hive

export SPARK_HOME=/opt/cloudera/parcels/CDH/lib/hive

export PATH=$PATH:${HADOOP_HOME}/bin:${HIVE_HOME}/bin:${SPARK_HOME}/bin
EOF

groupadd supergroup
usermod -a -G supergroup root
hdfs dfsadmin -refreshUserToGroupsMappings
