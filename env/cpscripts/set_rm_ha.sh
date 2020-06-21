#!/bin/bash
p="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "!!!Set HA for resource manager in yarn-site.xml..."
filename="$HADOOP_CONF_DIR/yarn-site.xml"
cp ${filename} ${filename}.bk."`date`" -f
$p/removename.sh ${filename} "yarn.resourcemanager.hostname"
$p/setvalue.sh ${filename} "yarn.resourcemanager.zk-address" "pro-hbase02:2181,pro-hbase02:2181,pro-hbase02:2181"
$p/setvalue.sh ${filename} "yarn.resourcemanager.store.class" "org.apache.hadoop.yarn.server.resourcemanager.recovery.ZKRMStateStore"
$p/setvalue.sh ${filename} "yarn.resourcemanager.recovery.enabled" "true"
$p/setvalue.sh ${filename} "yarn.resourcemanager.hostname.rm1" "pro-hbase01"
$p/setvalue.sh ${filename} "yarn.resourcemanager.hostname.rm2" "pro-hbase02"
$p/setvalue.sh ${filename} "yarn.resourcemanager.ha.rm-ids" "rm1,rm2"
$p/setvalue.sh ${filename} "yarn.resourcemanager.cluster-id" "harm"
$p/setvalue.sh ${filename} "yarn.resourcemanager.ha.enabled" "true"
