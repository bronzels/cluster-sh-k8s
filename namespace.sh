#rook-ceph
kubectl create namespace md
  #postgre
#kubectl create namespace mq
#kubectl delete namespace mq
  #shared by configmap for connectors
    #json/avro/bson
    #log4j
kubectl create namespace mqstr
  #zookeeper
  #kafka
kubectl create namespace mqdw
  #kafka
  #zookeeper
#k8s master
  #ssh
  #scripts/kubectl
    #mqstr confluent
      #mysqlsrc
      #postgresrc
    #mqdw confluent
      #mysqlsrc
        #cptrd
        #sam
        #strategy2
        #strategy
        #pyramid
      #mysqlsink2kudu
        #cptrd
        #sam
        #strategy2
        #strategy
        #pyramid
      #mongomaster
        #src
        #sink2slave
      #mongoslave
        #src
        #sink2kudu
      #tsdbsink2kudu
    #teardown/launch opentsdb(serv/servyat)
    #teardown/launch codis(serv/servyat)
kubectl create namespace hadoop
  #hadoop(zookeeper/hdfs/yarn/hive/hbase)
  #hadoopclient(spark/kylin/hive/hbase)
kubectl create namespace serv
  #codis
  #opentsdb
kubectl create namespace servyat
  #codis
  #opentsdb
kubectl create namespace dw
  #kudu
  #presto
kubectl create namespace workflow
  #airflow
    #ssh cligw
    #ssh tsdb
    #ssh k8s master
kubectl create namespace cligw
  #cligw
    #ssh
    #hadoop server(zookeeper/hdfs/yarn/hive/hbase)
    #spark
    #kylin server
    #flink
    #presto server
    #scripts/porting
      #hadoop(zookeeper/hdfs/yarn/hive/hbase)
      #spark
      #kylin
      #flink
      #presto
#default
  #prometheus operator
  #redis

kubectl get namespaces