strimzirev=0.18.0
wget -c https://github.com/strimzi/strimzi-kafka-operator/releases/download/0.18.0/strimzi-${strimzirev}.zip
unzip strimzi-${strimzirev}.zip
ln -s strimzi-${strimzirev} strimzi

cd ~/strimzi
kubectl apply -f install/strimzi-admin
#kubectl delete -f install/strimzi-admin
cp -r install/cluster-operator install/cluster-operator.bk
sed -i 's/namespace: .*/namespace: mq/' install/cluster-operator/*RoleBinding*.yaml

#          value: mqstr,mqdw
#          value: "*"
file=install/cluster-operator/050-Deployment-strimzi-cluster-operator.yaml
mv ${file} ${file}.bk
cat << EOF > install/cluster-operator/050-Deployment-strimzi-cluster-operator.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: strimzi-cluster-operator
  labels:
    app: strimzi
spec:
  replicas: 1
  selector:
    matchLabels:
      name: strimzi-cluster-operator
      strimzi.io/kind: cluster-operator
  template:
    metadata:
      labels:
        name: strimzi-cluster-operator
        strimzi.io/kind: cluster-operator
    spec:
      serviceAccountName: strimzi-cluster-operator
      containers:
      - name: strimzi-cluster-operator
        image: strimzi/operator:0.18.0
        ports:
        - containerPort: 8080
          name: http
        args:
        - /opt/strimzi/bin/cluster_operator_run.sh
        env:
        - name: STRIMZI_NAMESPACE
          value: mqstr,mqdw
        - name: STRIMZI_FULL_RECONCILIATION_INTERVAL_MS
          value: "120000"
        - name: STRIMZI_OPERATION_TIMEOUT_MS
          value: "300000"
        - name: STRIMZI_DEFAULT_TLS_SIDECAR_ENTITY_OPERATOR_IMAGE
          value: strimzi/kafka:0.18.0-kafka-2.5.0
        - name: STRIMZI_DEFAULT_TLS_SIDECAR_KAFKA_IMAGE
          value: strimzi/kafka:0.18.0-kafka-2.5.0
        - name: STRIMZI_DEFAULT_KAFKA_EXPORTER_IMAGE
          value: strimzi/kafka:0.18.0-kafka-2.5.0
        - name: STRIMZI_DEFAULT_CRUISE_CONTROL_IMAGE
          value: strimzi/kafka:0.18.0-kafka-2.5.0
        - name: STRIMZI_DEFAULT_TLS_SIDECAR_CRUISE_CONTROL_IMAGE
          value: strimzi/kafka:0.18.0-kafka-2.5.0
        - name: STRIMZI_KAFKA_IMAGES
          value: |
            2.4.0=strimzi/kafka:0.18.0-kafka-2.4.0
            2.4.1=strimzi/kafka:0.18.0-kafka-2.4.1
            2.5.0=strimzi/kafka:0.18.0-kafka-2.5.0
        - name: STRIMZI_KAFKA_CONNECT_IMAGES
          value: |
            2.4.0=strimzi/kafka:0.18.0-kafka-2.4.0
            2.4.1=strimzi/kafka:0.18.0-kafka-2.4.1
            2.5.0=strimzi/kafka:0.18.0-kafka-2.5.0
        - name: STRIMZI_KAFKA_CONNECT_S2I_IMAGES
          value: |
            2.4.0=strimzi/kafka:0.18.0-kafka-2.4.0
            2.4.1=strimzi/kafka:0.18.0-kafka-2.4.1
            2.5.0=strimzi/kafka:0.18.0-kafka-2.5.0
        - name: STRIMZI_KAFKA_MIRROR_MAKER_IMAGES
          value: |
            2.4.0=strimzi/kafka:0.18.0-kafka-2.4.0
            2.4.1=strimzi/kafka:0.18.0-kafka-2.4.1
            2.5.0=strimzi/kafka:0.18.0-kafka-2.5.0
        - name: STRIMZI_KAFKA_MIRROR_MAKER_2_IMAGES
          value: |
            2.4.0=strimzi/kafka:0.18.0-kafka-2.4.0
            2.4.1=strimzi/kafka:0.18.0-kafka-2.4.1
            2.5.0=strimzi/kafka:0.18.0-kafka-2.5.0
        - name: STRIMZI_DEFAULT_TOPIC_OPERATOR_IMAGE
          value: strimzi/operator:0.18.0
        - name: STRIMZI_DEFAULT_USER_OPERATOR_IMAGE
          value: strimzi/operator:0.18.0
        - name: STRIMZI_DEFAULT_KAFKA_INIT_IMAGE
          value: strimzi/operator:0.18.0
        - name: STRIMZI_DEFAULT_KAFKA_BRIDGE_IMAGE
          value: strimzi/kafka-bridge:0.16.0
        - name: STRIMZI_DEFAULT_JMXTRANS_IMAGE
          value: strimzi/jmxtrans:0.18.0
        - name: STRIMZI_LOG_LEVEL
          value: "INFO"
        livenessProbe:
          httpGet:
            path: /healthy
            port: http
          initialDelaySeconds: 10
          periodSeconds: 30
        readinessProbe:
          httpGet:
            path: /ready
            port: http
          initialDelaySeconds: 10
          periodSeconds: 30
        resources:
          limits:
            cpu: 1000m
            memory: 384Mi
          requests:
            cpu: 200m
            memory: 384Mi
  strategy:
    type: Recreate
EOF
diff install/cluster-operator/050-Deployment-strimzi-cluster-operator.yaml install/cluster-operator/050-Deployment-strimzi-cluster-operator.yaml.bk
kubectl apply -f install/cluster-operator/020-RoleBinding-strimzi-cluster-operator.yaml -n mqstr
#kubectl delete -f install/cluster-operator/020-RoleBinding-strimzi-cluster-operator.yaml -n mqstr
kubectl apply -f install/cluster-operator/031-RoleBinding-strimzi-cluster-operator-entity-operator-delegation.yaml -n mqstr
#kubectl delete -f install/cluster-operator/031-RoleBinding-strimzi-cluster-operator-entity-operator-delegation.yaml -n mqstr
kubectl apply -f install/cluster-operator/032-RoleBinding-strimzi-cluster-operator-topic-operator-delegation.yaml -n mqstr
#kubectl delete -f install/cluster-operator/032-RoleBinding-strimzi-cluster-operator-topic-operator-delegation.yaml -n mqstr
kubectl apply -f install/cluster-operator/020-RoleBinding-strimzi-cluster-operator.yaml -n mqdw
#kubectl delete -f install/cluster-operator/020-RoleBinding-strimzi-cluster-operator.yaml -n mqdw
kubectl apply -f install/cluster-operator/031-RoleBinding-strimzi-cluster-operator-entity-operator-delegation.yaml -n mqdw
#kubectl delete -f install/cluster-operator/031-RoleBinding-strimzi-cluster-operator-entity-operator-delegation.yaml -n mqdw
kubectl apply -f install/cluster-operator/032-RoleBinding-strimzi-cluster-operator-topic-operator-delegation.yaml -n mqdw
#kubectl delete -f install/cluster-operator/032-RoleBinding-strimzi-cluster-operator-topic-operator-delegation.yaml -n mqdw
kubectl apply -f install/cluster-operator -n mq
#kubectl delete -f install/cluster-operator -n mq
kubectl get deployments -n mq


cd ~/strimzi/examples
cat << EOF > kafka/kafka-persistent-custom.yaml
apiVersion: kafka.strimzi.io/v1beta1
kind: Kafka
metadata:
  name: mykafka
spec:
  kafka:
    version: 2.5.0
    replicas: 3
    listeners:
      plain: {}
      tls: {}
    config:
      offsets.topic.replication.factor: 3
      transaction.state.log.replication.factor: 3
      transaction.state.log.min.isr: 2
      log.message.format.version: "2.5"
      delete.topic.enable: true
      num.partitions: 12
      log.retention.hours: 168
    storage:
      type: jbod
      volumes:
      - id: 0
        type: persistent-claim
        size: 128Gi
        deleteClaim: false
  zookeeper:
    replicas: 3
    storage:
      type: persistent-claim
      size: 16Gi
      deleteClaim: false
  entityOperator:
    topicOperator: {}
    userOperator: {}
EOF
diff kafka/kafka-persistent.yaml kafka/kafka-persistent-custom.yaml

kubectl get pvc -n mqstr
kubectl get pvc -n mqstr|grep mykafka|awk '{print $1}'|xargs kubectl -n mqstr delete pvc

kubectl apply -f kafka/kafka-persistent-custom.yaml -n mqstr
kubectl wait kafka/mykafka --for=condition=Ready --timeout=300s -n mqstr
#kubectl delete -f kafka/kafka-persistent-custom.yaml -n mqstr
kubectl get kafka -n mqstr
kubectl get pod -n mqstr
kubectl get svc -n mqstr -o wide

kubectl -n default run test-kafka-producer-mqstr -ti --image=strimzi/kafka:0.18.0-kafka-2.5.0 --rm=true --restart=Never -- bin/kafka-console-producer.sh --broker-list mykafka-kafka-bootstrap.mqstr:9091,mykafka-kafka-bootstrap.mqstr:9092,mykafka-kafka-bootstrap.mqstr:9093 --topic test
kubectl -n default run test-kafka-consumer-mqstr -ti --image=strimzi/kafka:0.18.0-kafka-2.5.0 --rm=true --restart=Never -- bin/kafka-console-consumer.sh --bootstrap-server mykafka-kafka-bootstrap.mqstr:9091,mykafka-kafka-bootstrap.mqstr:9092,mykafka-kafka-bootstrap.mqstr:9093 --topic test
kubectl -n default run test-kafka-consumer-mqstr -ti --image=strimzi/kafka:0.18.0-kafka-2.5.0 --env="KAFKA_HEAP_OPTS=-Xmx1024M" --rm=true --restart=Never -- bin/kafka-run-class.sh kafka.tools.GetOffsetShell --broker-list mykafka-kafka-bootstrap.mqstr:9091,mykafka-kafka-bootstrap.mqstr:9092,mykafka-kafka-bootstrap.mqstr:9093 --topic test --time -1 --offsets 1

kubectl get pvc -n mqdw
kubectl get pvc -n mqdw|grep mykafka|awk '{print $1}'|xargs kubectl -n mqdw delete pvc

kubectl apply -f kafka/kafka-persistent-custom.yaml -n mqdw
kubectl wait kafka/mykafka --for=condition=Ready --timeout=300s -n mqdw
#kubectl delete -f kafka/kafka-persistent-custom.yaml -n mqdw
kubectl get kafka -n mqdw
kubectl get pod -n mqdw
kubectl get svc -n mqdw -o wide


#refer to this to change cluster CRD online to increase kafka/zookeeper pv size
#https://strimzi.io/blog/2019/07/08/persistent-storage-improvements/

kubectl -n default run test-kafka-producer-mqdw -ti --image=strimzi/kafka:0.18.0-kafka-2.5.0 --rm=true --restart=Never -- bin/kafka-console-producer.sh --broker-list mykafka-kafka-bootstrap.mqdw:9091,mykafka-kafka-bootstrap.mqdw:9092,mykafka-kafka-bootstrap.mqdw:9093 --topic test
kubectl -n default run test-kafka-consumer-mqdw -ti --image=strimzi/kafka:0.18.0-kafka-2.5.0 --rm=true --restart=Never -- bin/kafka-console-consumer.sh --bootstrap-server mykafka-kafka-bootstrap.mqdw:9091,mykafka-kafka-bootstrap.mqdw:9092,mykafka-kafka-bootstrap.mqdw:9093 --topic test
kubectl -n default run test-kafka-consumer-mqdw -ti --image=strimzi/kafka:0.18.0-kafka-2.5.0 --env="KAFKA_HEAP_OPTS=-Xmx1024M" --rm=true --restart=Never -- bin/kafka-run-class.sh kafka.tools.GetOffsetShell --broker-list mykafka-kafka-bootstrap.mqdw:9091,mykafka-kafka-bootstrap.mqdw:9092,mykafka-kafka-bootstrap.mqdw:9093 --topic test --time -1 --offsets 1
