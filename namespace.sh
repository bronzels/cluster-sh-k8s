#rook-ceph
kubectl create namespace md
  #postgre
kubectl create namespace mqstr
  #zookeeper
  #kafka
kubectl create namespace mqdw
  #zookeeper
  #kafka
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
kubectl create namespace serv
  #codis
  #opentsdb
kubectl create namespace servyat
  #codis
  #opentsdb
kubectl create namespace dw
  #kudu
  #presto
kubectl create namespace str
  #flink
kubectl create namespace fl
  #airflow
    #ssh cligw
    #ssh tsdb
    #ssh k8s master
#default
  #prometheus operator
  #redis
kubectl create namespace hadoop
  #zookeeper
  #hadoop
  #hbase
  #kylin

kubectl get namespaces
