kubectl get pvc -n mqstr
kubectl get pvc -n mqstr|grep mykafka|awk '{print $1}'|xargs kubectl -n mqstr delete pvc

helm install mykafka incubator/kafka -n mqstr \
  --set replicas=3 \
  --set persistence.size=256Gi \
  --set zookeeper.storage=16Gi \
	--set configurationOverrides."confluent\.support\.metrics\.enable"=true \
	--set configurationOverrides."delete\.topic\.enable"=true \
	--set configurationOverrides."num\.partitions"=12 \
	--set configurationOverrides."log\.retention\.hours"=168
#helm uninstall mykafka -n mqstr

kubectl get pod -n mqstr
kubectl get svc -n mqstr -o wide

kubectl -n default run test-kafka-producer-mqstr -ti --image=strimzi/kafka:0.18.0-kafka-2.5.0 --rm=true --restart=Never -- bin/kafka-console-producer.sh --broker-list mykafka.mqstr:9092 --topic test
kubectl -n default run test-kafka-consumer-mqstr -ti --image=strimzi/kafka:0.18.0-kafka-2.5.0 --rm=true --restart=Never -- bin/kafka-console-consumer.sh --bootstrap-server mykafka.mqstr:9092 --topic test
kubectl -n default run test-kafka-consumer-mqstr -ti --image=strimzi/kafka:0.18.0-kafka-2.5.0 --env="KAFKA_HEAP_OPTS=-Xmx1024M" --rm=true --restart=Never -- bin/kafka-run-class.sh kafka.tools.GetOffsetShell --broker-list mykafka.mqstr:9092 --topic test --time -1 --offsets 1


kubectl get pvc -n mqdw
kubectl get pvc -n mqdw|grep mykafka|awk '{print $1}'|xargs kubectl -n mqdw delete pvc

helm install mykafka incubator/kafka -n mqdw \
  --set replicas=3 \
  --set persistence.size=256Gi \
  --set zookeeper.storage=16Gi \
	--set configurationOverrides."confluent\.support\.metrics\.enable"=true \
	--set configurationOverrides."delete\.topic\.enable"=true \
	--set configurationOverrides."num\.partitions"=12 \
	--set configurationOverrides."log\.retention\.hours"=168
#helm uninstall mykafka -n mqdw

kubectl get pod -n mqdw
kubectl get svc -n mqdw -o wide

kubectl -n default run test-kafka-producer-mqdw -ti --image=strimzi/kafka:0.18.0-kafka-2.5.0 --rm=true --restart=Never -- bin/kafka-console-producer.sh --broker-list mykafka.mqdw:9092 --topic test
kubectl -n default run test-kafka-consumer-mqdw -ti --image=strimzi/kafka:0.18.0-kafka-2.5.0 --rm=true --restart=Never -- bin/kafka-console-consumer.sh --bootstrap-server mykafka.mqdw:9092 --topic test
kubectl -n default run test-kafka-consumer-mqdw -ti --image=strimzi/kafka:0.18.0-kafka-2.5.0 --env="KAFKA_HEAP_OPTS=-Xmx1024M" --rm=true --restart=Never -- bin/kafka-run-class.sh kafka.tools.GetOffsetShell --broker-list mykafka.mqdw:9092 --topic test --time -1 --offsets 1

:<<EOF
#  --set kafkaStore.overrideBootstrapServer=mykafka.mqdw:9092 \
#  --set configurationOverrides."kafkastore\.connection\.url"=mykafka-zookeeper.mqdw:2181 \
#  --set configurationOverrides."bootstrap\.servers"=mykafka.mqdw:9092 \
helm install mysr incubator/schema-registry  -n mqdw \
  --set replicaCount=2 \
  --set kafka.enabled=false
#helm uninstall mysr -n mqdw
EOF

cd ~/charts/incubator/schema-registry/
file=values.yaml
mv ${file} ${file}.bk

cat << \EOF > ${file}
# Default values for Confluent Schema-Registry
# This is a YAML-formatted file.
# Declare name/value pairs to be passed into your templates.
# name: value


## schema-registry repository
image: "confluentinc/cp-schema-registry"
## The container tag to use
imageTag: 5.0.1
## Specify a imagePullPolicy
## ref: http://kubernetes.io/docs/user-guide/images/#pre-pulling-images
imagePullPolicy: "IfNotPresent"

## Number of Schema Registry Pods to Deploy
replicaCount: 2

## Schema Registry Settings Overrides
## Configuration Options can be found here: https://docs.confluent.io/current/schema-registry/docs/config.html
configurationOverrides: {}
  ## The default master.eligiblity is true
  # master.eligibility: false

## Custom pod annotations
podAnnotations: {}

## Configure resource requests and limits
## ref: http://kubernetes.io/docs/user-guide/compute-resources/
## Confluent has production deployment guidelines here:
## ref: https://github.com/confluentinc/schema-registry/blob/master/docs/deployment.rst
##
resources: {}
  # limits:
  #  cpu: 100m
  #  memory: 128Mi
  # requests:
  #  cpu: 100m
  #  memory: 128Mi

## The port on which the SchemaRegistry will be available and serving requests
servicePort: 8081

## Provides schema registry service settings
service:
  ## Any annotations to add to the service
  annotations: {}
  ## Any additional labels to add to the service
  labels: {}

## If `Kafka.Enabled` is `false`, kafkaStore.overrideBootstrapServers must be provided for Master Election.
## You can list load balanced service endpoint, or list of all brokers (which is hard in K8s).  e.g.:
## overrideBootstrapServers: "PLAINTEXT://dozing-prawn-kafka-headless:9092"
## Charts uses Kafka Coordinator Master Election: https://docs.confluent.io/current/schema-registry/docs/design.html#kafka-coordinator-master-election
kafkaStore:
  overrideBootstrapServers: "PLAINTEXT://mykafka.mqdw:9092"
  # By Default uses Release Name, but can be overridden.  Which means each release is its own group of
  # Schema Registry workers.  You can have multiple groups talking to same Kafka Cluster
  overrideGroupId: ""
  ## Additional Java arguments to pass to Kafka.
  # schemaRegistryOpts: -Dfoo=bar

## Liveness and readiness probe config.
## ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/
##
livenessProbe:
  httpGet:
    path: /
    port: 8081
  initialDelaySeconds: 10
  timeoutSeconds: 5
readinessProbe:
  httpGet:
    path: /
    port: 8081
  initialDelaySeconds: 10
  periodSeconds: 10
  timeoutSeconds: 5
  successThreshold: 1
  failureThreshold: 3

# Options for connecting to SASL kafka brokers
sasl:
  configPath: "/etc/kafka-config"
  scram:
    enabled: false
    init:
      image: "confluentinc/cp-schema-registry"
      imageTag: "5.0.1"
      imagePullPolicy: "IfNotPresent"
    clientUser: "kafka-client"
    zookeeperClientUser: "zookeeper-client"
    # Passwords can be either provided here or pulled from an existing k8s secret.
    # If user wants to specify the password here:
    clientPassword: "client-password"
    zookeeperClientPassword: "zookeeper-client-password"
    # If user has an existing k8s secret they would like to use instead of generating them:
    # useExistingSecret:
    #   # Where to find the schema registry user secret
    #   clientPassword:
    #     secretKeyRef:
    #       name: "schema-reg-secret"
    #       key: "client-password"
    #   # Where to find the zookeeper user secret
    #   zookeeperClientPassword:
    #     secretKeyRef:
    #       name: "zookeeper-secret"
    #       key: "zokeeper-client-password"

## Kafka Settings
kafka:
  ## This is enabled only to allow installations of this chart without arguments
  enabled: false
  ## Override kafka settings for default installations
  configurationOverrides:
    # Needed to run with 1 Kafka Broker
    offsets.topic.replication.factor: 1
  ## Run only a single kafka broker by default
  replicas: 1

  ## Kafka Zookeeper chart settings
  zookeeper:
    # Install only a single Zookeeper pod in the StatefulSet
    replicaCount: 1

## Provides schema registry ingress settings
ingress:
  ## If true provide ingress to the schema registry
  enabled: false
  ## Annotations for the ingress, if any
  annotations: {}
  ## Hostname of the ingress
  hostname: ""
  ## Any additional labels to add to the ingress
  labels: {}
  tls:
    enabled: false
    secretName: schema-registry-tls

## External Nodeport/LoadBalancer for Cloud Providers
external:
  enabled: false
  type: LoadBalancer
  servicePort: 443
  loadBalancerIP: ""
  nodePort: ""
  annotations: {}

## Provide JMX Port
jmx:
  enabled: true
  port: 5555

## Prometheus Exporter Configuration
## ref: https://prometheus.io/docs/instrumenting/exporters/
prometheus:
  ## JMX Exporter Configuration
  ## ref: https://github.com/prometheus/jmx_exporter
  jmx:
    enabled: false
    image: solsson/kafka-prometheus-jmx-exporter@sha256
    imageTag: 6f82e2b0464f50da8104acd7363fb9b995001ddff77d248379f8788e78946143
    port: 5556
    resources: {}
      # limits:
      #  cpu: 100m
      #  memory: 128Mi
      # requests:
      #  cpu: 100m
      #  memory: 128Mi

## Pass any secrets to the pods. The secrets will be mounted to a specfic path
## OR presented as Environment Variables. Environment variable names are
## generated as: `<secretName>_<secretKey>` (All upper case)
## note: Keystore/Truststore are binary and should always be presented as files.
secrets: []
# - name: schema-registry-jks
#   keys:
#     - ksr-server.truststore.jks
#     - ksr-server.keystore.jks
#   mountPath: /secrets
# - name: schema-registry-jks-pw
#   keys:
#     - ssl_truststore_password
#     - ssl_keystore_password
#     - ssl_key_password
EOF
diff ${file}.bk ${file}

#helm install -f values.yaml mysr . -n mqdw
helm install mysr -f values.yaml incubator/schema-registry -n mqdw
#helm uninstall mysr -n mqdw

kubectl get pod -n mqdw
kubectl get svc -n mqdw -o wide

:<<EOF
You can connect to Kafka by running a simple pod in the K8s cluster like this with a configuration like this:

  apiVersion: v1
  kind: Pod
  metadata:
    name: testclient
    namespace: mq
  spec:
    containers:
    - name: kafka
      image: confluentinc/cp-kafka:5.0.1
      command:
        - sh
        - -c
        - "exec tail -f /dev/null"

Once you have the testclient pod above running, you can list all kafka
topics with:

  kubectl -n mq exec testclient -- ./bin/kafka-topics.sh --zookeeper mykafka-zookeeper:2181 --list

To create a new topic:

  kubectl -n mq exec testclient -- ./bin/kafka-topics.sh --zookeeper mykafka-zookeeper:2181 --topic test1 --create --partitions 1 --replication-factor 1

To listen for messages on a topic:

  kubectl -n mq exec -ti testclient -- ./bin/kafka-console-consumer.sh --bootstrap-server mykafka:9092 --topic test1 --from-beginning

To stop the listener session above press: Ctrl+C

To start an interactive message producer session:
  kubectl -n mq exec -ti testclient -- ./bin/kafka-console-producer.sh --broker-list mykafka-headless:9092 --topic test1

To create a message in the above session, simply type the message and press "enter"
To end the producer session try: Ctrl+C

If you specify "zookeeper.connect" in configurationOverrides, please replace "mykafka-zookeeper:2181" with the value of "zookeeper.connect", or you will get error.
EOF

:<<EOF
1. Get the application URL by running these commands:
  export POD_NAME=$(kubectl get pods --namespace mqdw -l "app=schema-registry,release=mysr" -o jsonpath="{.items[0].metadata.name}")
  echo "Visit http://127.0.0.1:8080 to use your application"
  kubectl port-forward $POD_NAME 8080:8081
EOF
