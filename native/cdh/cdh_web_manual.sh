curl http://slave01:7180/
:<<EOF
访问cloudera-manager
浏览器输入http://slave01:7180/
用户/密码：admin/admin
按照向导搭建集群。
注意：
  安装以下组件：
    HBase
    HDFS
    Hive
    Kudu
    Spark 2
    YARN (MR2 Included)
    ZooKeeper
    Sqoop（部署在slave01）
  所有本地目录设置指向/app数据盘挂载位置
有问题查看日志解决
EOF

#以下warning可以surpress：
:<<EOF
  HDFS
    Erasure Coding Policy Verification Test Suppressing...
    Cloudera Management Service: Maximum Non-Java Memory of Host Monitor Suppress...
  The recommended non-Java memory size is 2.0 GiB, 512.0 MiB more than is configured.
    Cloudera Management Service: Java Heap Size of Service Monitor in Bytes Suppress...
  The recommended heap size is 2.0 GiB bytes, 1.0 GiB more than is configured.
    Cloudera Management Service: Maximum Non-Java Memory of Service Monitor Suppress...
  The recommended non-Java memory size is 12.0 GiB, 10.5 GiB more than is configured.
    Service Monitor (hk-prod-bigdata-slave-0-31): Java Heap Size of Service Monitor in Bytes Suppress...
  The recommended heap size is 2.0 GiB bytes, 1.0 GiB more than is configured.
EOF

#解决cloudera内存被调拨过度
  #“0.8”值是Cloudera Manager中的默认值，需要根据具体主机的环境进行调整。
  #对于具有16G内存的主机，预留20%的操作系统内存（3.2G）可能还不够。
  #对于具有256G内存的主机，预留20%的操作系统内存（51.2G）可能太多了。
#设置host
#在host的configuration页面，
  #找到：Memory Overcommit Validation Threshold
    #设置为：0.9325（以内存128为例，1-8/128）(缺省0.8)

#解决root用户hdfs权限问题
groupadd supergroup
usermod -a -G supergroup root
hdfs dfsadmin -refreshUserToGroupsMappings

#ansible allcdh -m shell -a"cd ~;ln -s $HIVE_HOME hive"
#安装wizard完成以后再新增service;Sqoop 1 Client，配置在slave01
cd ~
ln -s /opt/cloudera/parcels/CDH/lib/sqoop sqoop
cp ~/cdh/mysql-connector-java.jar sqoop/lib/

ln -s /opt/cloudera/parcels/CDH/lib/hive hive

#  #找到：yarn.nodemanager.resource.memory-mb
#    #设置为：102400(缺省47493MiB)
#设置yarn的scheduler资源
#在yarn的configuration页面，
  #找到：yarn.nodemanager.resource.cpu-vcores
    #设置为：8(缺省16)
  #找到：mapreduce.map.memory.mb
    #设置为：5(缺省0)Gib
  #找到：mapreduce.reduce.memory.mb
    #设置为：5(缺省0)Gib
  #找到：yarn.scheduler.minimum-allocation-mb
    #设置为：2(缺省1)Gib
  #找到：yarn.resourcemanager.scheduler.class
    #确保设置为org.apache.hadoop.yarn.server.resourcemanager.scheduler.fair.FairScheduler
  #找到：Fair Scheduler XML Advanced Configuration Snippet (Safety Valve)
    #把以下xml内容设置进去
#       <maxResources>204800 mb, 36 vcores</maxResources>
:<<EOF
<allocations>
    <queue name="default">
    <minSharePreemptionTimeout>300</minSharePreemptionTimeout>
    <weight>1.0</weight>
       <maxRunningApps>7</maxRunningApps>
       <minResources>6144 mb, 3 vcores</minResources>
       <maxResources>98304 mb, 18 vcores</maxResources>
    </queue>
    <queue name="other">
    <minSharePreemptionTimeout>300</minSharePreemptionTimeout>
    <weight>1.0</weight>
       <maxRunningApps>1</maxRunningApps>
       <minResources>6144 mb, 3 vcores</minResources>
       <maxResources>6144 mb, 3 vcores</maxResources>
    </queue>
  <user name="root">
    <maxRunningApps>7</maxRunningApps>
  </user>
  <userMaxAppsDefault>7</userMaxAppsDefault>
  <fairSharePreemptionTimeout>6000</fairSharePreemptionTimeout>
</allocations>
EOF

#hbase thrift server的端口和后续ceph的端口冲突
#在hbase的configuration页面，
  #找到：hbase.regionserver.thrift.port
    #设置为9050
  #重启thrift server
#设置hbase资源
#在hbase的configuration页面，
  #找到：Java Heap Size of HBase Master in Bytes
    #设置为：4(缺省1)G
  #找到：Java Heap Size of HBase RegionServer in Bytes
    #确保设置为：31(缺省31)G
  #找到：hbase.master.handler.count
    #确保设置为：48(缺省25)
  #找到：hbase.regionserver.handler.count
    #确保设置为：128(缺省30)
  #找到：hbase.client.write.buffer
    #确保设置为：4(缺省2)M

#设置spark
ansible allcdh -m shell -a"mkdir -p /app/spark/history"
#在spark的configuration页面，
  #找到：spark.history.store.path
    #设置为：/app/spark/history(缺省/var/lib/spark/history)

#！！！如果presto已经安装，重新安装cdh/kudu，需要参考presto.sh中说明，重新设置kudu的schema

#确保整个cdh系统
  #没有warning
  #没有staple configuration待重启更新
