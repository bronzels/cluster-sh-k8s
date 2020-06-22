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
kubectl create namespace serv
  #codis
  #opentsdb
kubectl create namespace servyat
  #codis
  #opentsdb
kubectl create namespace dw
  #presto
kubectl create namespace flow
  #airflow
    #ssh cligw
    #ssh tsdb
    #ssh k8s master
#default
  #prometheus operator
  #redis
  #flink

kubectl get namespaces
