#hbase thrift server的端口和ceph的端口冲突
#在hbase的configuration页面，
  #找到：hbase.regionserver.thrift.port
    #设置为9050
  #重启thrift server

#设置yarn的scheduler资源
#在yarn的configuration页面，
  #找到：yarn.nodemanager.resource.cpu-vcores
    #设置为：12(缺省16)
  #找到：mapreduce.map.memory.mb
    #设置为：5Gib(缺省0)
  #找到：mapreduce.reduce.memory.mb
    #设置为：5Gib(缺省0)
  #找到：yarn.scheduler.minimum-allocation-mb
    #设置为：2Gib(缺省1)
  #找到：yarn.resourcemanager.scheduler.class
    #确保设置为org.apache.hadoop.yarn.server.resourcemanager.scheduler.fair.FairScheduler
  #找到：Fair Scheduler XML Advanced Configuration Snippet (Safety Valve)
    #把以下xml内容设置进去
:<<EOF
<allocations>
    <queue name="default">
    <minSharePreemptionTimeout>300</minSharePreemptionTimeout>
    <weight>1.0</weight>
       <maxRunningApps>7</maxRunningApps>
       <minResources>6144 mb, 3 vcores</minResources>
       <maxResources>204800 mb, 21 vcores</maxResources>
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

#设置hbase资源
#在hbase的configuration页面，
  #找到：Java Heap Size of HBase Master in Bytes
    #设置为4G(缺省1G)
  #找到：Java Heap Size of HBase RegionServer in Bytes
    #确保设置为31G(缺省31G)
  #找到：hbase.master.handler.count
    #确保设置为48(缺省25)
  #找到：hbase.regionserver.handler.count
    #确保设置为128(缺省30)
  #找到：hbase.client.write.buffer
    #确保设置为4M(缺省2M)

#设置spark
ansible allcdh -m shell -a"mkdir -p /app/spark/history"
#在spark的configuration页面，
  #找到：spark.history.store.path
    #设置为/app/spark/history(缺省/var/lib/spark/history)

#以下warning可以surpress：
  #

#确保整个cdh系统
  #没有warning
  #没有configuration待staple
