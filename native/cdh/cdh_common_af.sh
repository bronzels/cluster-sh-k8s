#root

cd ~/cdh
wget -c https://cdn.mysql.com//archives/mysql-connector-java-5.1/mysql-connector-java-5.1.46.tar.gz
tar xzvf mysql-connector-java-5.1.46.tar.gz
cp mysql-connector-java-5.1.46/
ansible allcdh -m copy -a"src=~/cdh/mysql-connector-java.jar dest=/usr/share/java"
ansible allcdh -m shell -a"ls -l /usr/share/java/mysql-connector-java.jar"

file=/etc/cloudera-scm-agent/config.ini
cp ${file} ${file}.bk
sed -i 's@server_host=localhost@server_host=hk-prod-bigdata-slave-1-245@g' ${file}
ansible slavecdh -m copy -a"src=/etc/cloudera-scm-agent/config.ini dest=/etc/cloudera-scm-agent"

systemctl start cloudera-scm-server
tail -f /var/log/cloudera-scm-server/cloudera-scm-server.log
#会提示无法下载sqoop 404 URI，重新stop/start就好了

ansible allcdh -m shell -a"sysctl vm.swappiness=10"
ansible allcdh -m shell -a"echo 'vm.swappiness=10'>> /etc/sysctl.conf"

#each
kill -9 $(pgrep -f supervisord)
ansible allcdh -m shell -a"systemctl start cloudera-scm-agent"
ansible allcdh -m shell -a"tail -100 /var/log/cloudera-scm-agent/cloudera-scm-agent.log"

:<<EOF
访问cloudera-manager
浏览器输入http://deploy01:7180/
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
EOF