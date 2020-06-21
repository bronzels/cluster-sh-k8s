#!/bin/bash
p="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "!!!Set HA for name node in core-site.xml..."
filename="$HADOOP_CONF_DIR/core-site.xml"
cp ${filename} ${filename}.bk."`date`" -f
$p/setvalue.sh ${filename} "fs.defaultFS" "hdfs:\/\/hamasters"
$p/setvalue.sh ${filename} "ha.zookeeper.quorum" "pro-hbase02:2181,pro-hbase03:2181,pro-hbase04:2181"

echo "!!!Set HA for name node in hdfs-site.xml..."
filename="$HADOOP_HOME/etc/hadoop/hdfs-site.xml"
cp ${filename} ${filename}.bk."`date`" -f
$p/setvalue.sh ${filename} "dfs.nameservices" "hamasters"
$p/setvalue.sh ${filename} "dfs.ha.namenodes.hamasters" "nn1,nn2"
$p/removename.sh ${filename} "dfs.http.address"
$p/setvalue.sh ${filename} "dfs.namenode.rpc-address.hamasters.nn1" "pro-hbase01:50090"
$p/setvalue.sh ${filename} "dfs.namenode.http-address.hamasters.nn1" "pro-hbase01:50070"
$p/setvalue.sh ${filename} "dfs.namenode.rpc-address.hamasters.nn2" "pro-hbase02:50090"
$p/setvalue.sh ${filename} "dfs.namenode.http-address.hamasters.nn2" "pro-hbase02:50070"
$p/setvalue.sh ${filename} "dfs.namenode.shared.edits.dir" "qjournal:\/\/pro-hbase01:8485;pro-hbase02:8485;pro-hbase03:8485\/hamasters"
$p/setvalue.sh ${filename} "dfs.journalnode.edits.dir" "\/app\/hadoop\/hadoop\/journal"
$p/setvalue.sh ${filename} "dfs.ha.automatic-failover.enabled" "true"
$p/setvalue.sh ${filename} "dfs.client.failover.proxy.provider.hamasters" "org.apache.hadoop.hdfs.server.namenode.ha.ConfiguredFailoverProxyProvider"
$p/setvalue.sh ${filename} "dfs.ha.fencing.methods" "\n         sshfence\n         shell(/bin/true)\n      "
$p/setvalue.sh ${filename} "dfs.ha.fencing.ssh.private-key-files" "\/app\/hadoop\/.ssh\/id_rsa"
$p/setvalue.sh ${filename} "dfs.ha.fencing.ssh.connect-timeout" "30000"
$p/removename.sh ${filename} "dfs.namenode.secondary.http-address"
cp $HADOOP_CONF_DIR/masters $HADOOP_CONF_DIR/masters."`date`" -f
echo "" > $HADOOP_CONF_DIR/masters
