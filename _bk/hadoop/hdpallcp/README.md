hdpallcp
====
Hadoop and all relevant or irrelevant client is started with SSH enable as stateful set. Hive server2 and Kylin server is started by same bootstrap.sh by different statefulset name.

Current chart version is `0.1.0`

Source code can be found [here](https://github.com/bronzels/cluster-sh-k8s/blob/master/hadoop/hadoop_hdpallcli.sh)

## Chart Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://master01:30500 | hbase:(HBASEREV)-hadoop(HADOOPREV) | ~0.1 |

## Chart Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| conf.hbaseSite | string | configMapName |  |
| conf.hiveSite | string | configMapName |  |
| conf.hadoopConfigMap | string | configMapName |  |
