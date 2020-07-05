cd ~
rev=3.0.2
#rev=3.1.0

wget -c https://mirrors.koehn.com/apache/kylin/apache-kylin-${rev}/apache-kylin-${rev}-bin-cdh60.tar.gz
tar xzvf apache-kylin-${rev}-bin-cdh60.tar.gz
rm -f kylin
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

echo "export SPARK_HOME=/opt/cloudera/parcels/CDH/lib/spark" >> ~/other-env.sh
echo "export KYLIN_HOME=${HOME}/kylin" >> ~/other-env.sh
source ~/.bashrc
echo $SPARK_HOME
echo $KYLIN_HOME

:<<EOF
file=/opt/cloudera/parcels/CDH/lib/hbase/bin/hbase
cp ${file} ${file}.bk
echo "CLASSPATH=${CLASSPATH}:$JAVA_HOME/lib/tools.jar:/opt/cloudera/parcels/CDH/lib/hbase/lib/*" >> ${file}
EOF

cp /opt/cloudera/cm/lib/commons-configuration-1.9.jar ~/kylin/lib/

~/kylin/bin/kylin.sh start

#如果出现问题，需要清空hdfs/zookeeper/hbase相关配置和数据再重启
:<<EOF
~/kylin/bin/kylin.sh stop
myzk_cli.sh "ls /"
myzk_cli.sh "deleteall /kylin"
hadoop fs -ls /
hadoop fs -rm -r -f /kylin
EOF
exec hbase shell <<EOF
list
EOF
exec hbase shell <<EOF
disable 'kylin_metadata'
drop 'kylin_metadata'
EOF

#https://community.cloudera.com/t5/Support-Questions/CDH-hive-install-issues/m-p/296502
#1. Open /opt/cloudera/cm-agent/service/common/cloudera-config.sh and search for function replace_hive_hbase_jars_template.
#2. Here you will notice "HBASE_JAR=$(sed "s: :,:g" <<< ..... " it is this command that appends the hbase jars to the classpath. It looks like on ubuntu 18 this command in not replacing whitespaces with ",". You can experiment. On the terminal itself try running "sed "s: :,:g" <<< $(printf "a\nb\nc\n")  "  You will notice that it is not replacing new line with "," .
#3. I don't know much about bash/shell scripting but one command that I tried and seems to be working is " tr '\n' ',' <<< $(printf "a\nb\nc\n")  ".
#4. Try this and see this works.
#Once you have the right command. Simply redeploy client config on each host.
#关于~/kylin/bin/sample.sh会报告以下错误，这是已知错误不影响kylin使用

~/kylin/bin/sample.sh
exec hbase shell <<EOF
list
EOF
#http://slave01:7070
#admin/KYLIN
#检查kylin_sales_cube/kylin_streaming_cube是否存在
#构建kylin_sales_cube，检查yarn web ui的资源占用情况，和是否用spark做构建引擎
