cd ~
rev=3.0.2

wget -c https://mirrors.koehn.com/apache/kylin/apache-kylin-${rev}/apache-kylin-${rev}-bin-cdh60.tar.gz
tar xzvf apache-kylin-${rev}-bin-cdh60.tar.gz
ln -s apache-kylin-${rev}-bin-cdh60 kylin

cd ~/kylin

file=conf/kylin.properties
cp ${file} ${file}.bk
cat << \EOF >> ${file}
kylin.web.query-timeout=3000000

kylin.source.hive.keep-flat-table=true
kylin.source.hive.quote-enabled=false

kylin.storage.hbase.coprocessor-mem-gb=30
kylin.storage.partition.max-scan-bytes=0
kylin.storage.hbase.coprocessor-timeout-seconds=270

kylin.engine.spark-conf.spark.master=yarn
kylin.engine.spark-conf.spark.submit.deployMode=cluster
kylin.engine.spark-conf.spark.yarn.queue=default
kylin.engine.spark-conf.spark.driver.memory=2G
kylin.engine.spark-conf.spark.executor.memory=5G
kylin.engine.spark-conf.spark.executor.instances=40
kylin.engine.spark-conf.spark.yarn.executor.memoryOverhead=2048
kylin.engine.spark-conf.spark.shuffle.service.enabled=true
kylin.engine.spark-conf.spark.eventLog.enabled=true
kylin.engine.spark-conf.spark.eventLog.dir=hdfs\:///kylin/spark-history
kylin.engine.spark-conf.spark.history.fs.logDirectory=hdfs\:///kylin/spark-history
kylin.engine.spark-conf.spark.hadoop.yarn.timeline-service.enabled=false
kylin.engine.spark-conf-mergedict.spark.executor.memory=2G
kylin.engine.spark-conf-mergedict.spark.memory.fraction=0.2

kylin.job.scheduler.default=2
kylin.job.lock=org.apache.kylin.storage.hbase.util.ZookeeperJobLock
EOF

echo "export KYLIN_HOME=${HOME}/kylin" >> ~/other-env.sh

#！！！手工，重新登录root
echo $KYLIN_HOME

:<<EOF
file=/opt/cloudera/parcels/CDH/lib/hbase/bin/hbase
cp ${file} ${file}.bk
echo "CLASSPATH=${CLASSPATH}:$JAVA_HOME/lib/tools.jar:/opt/cloudera/parcels/CDH/lib/hbase/lib/*" >> ${file}
EOF

cp /opt/cloudera/cm/lib/commons-configuration-1.9.jar ~/kylin/lib/

~/kylin/bin/kylin.sh start

~/kylin/bin/kylin.sh stop
myzk_cli.sh "ls /"
myzk_cli.sh "deleteall /kylin"
hadoop fs -ls /
hadoop fs -rm -r -f /kylin
exec hbase shell <<EOF
list
EOF
exec hbase shell <<EOF
disable 'kylin_metadata'
drop 'kylin_metadata'
EOF

#http://slave01:7070
#检查kylin_sales_cube/kylin_streaming_cube是否存在
#构建kylin_sales_cube
kylin/bin/sample.sh
~/kylin/bin/kylin.sh stop
~/kylin/bin/kylin.sh start
