
rm -rf ~/mykc
mkdir ~/mykc

cd ~/mykc

cat << \EOF > ~/mykc/connect-distributed.properties.json
value.converter.schemas.enable=false
internal.key.converter.schemas.enable=false
internal.value.converter.schemas.enable=false
internal.key.converter=org.apache.kafka.connect.json.JsonConverter
internal.value.converter=org.apache.kafka.connect.json.JsonConverter
plugin.path=/opt/confluent/share/java
rest.port=8083

key.converter=org.apache.kafka.connect.json.JsonConverter
value.converter=org.apache.kafka.connect.json.JsonConverter

group.id=connector_test_grp1
config.storage.topic=connector_config_test_tpc1
offset.storage.topic=connector_offset_test_tpc1
status.storage.topic=connector_status_test_tpc1

bootstrap.servers=mybootstrap
EOF
cat << \EOF > ~/mykc/connect-distributed.properties.avro
internal.key.converter.schemas.enable=false
internal.value.converter.schemas.enable=false
internal.key.converter=org.apache.kafka.connect.json.JsonConverter
internal.value.converter=org.apache.kafka.connect.json.JsonConverter
plugin.path=/app/hadoop/confluent/share/java
rest.port=8083
compression.type=lz4

key.converter=io.confluent.connect.avro.AvroConverter
value.converter=io.confluent.connect.avro.AvroConverter

group.id=connector_test_grp1
config.storage.topic=connector_config_test_tpc1
offset.storage.topic=connector_offset_test_tpc1
status.storage.topic=connector_status_test_tpc1

key.converter.schema.registry.url=http://mysr-schema-registry:8081
value.converter.schema.registry.url=http://mysr-schema-registry:8081

bootstrap.servers=mybootstrap
EOF
cat << \EOF > ~/mykc/connect-distributed.properties.bson
value.converter.schemas.enable=false
internal.key.converter.schemas.enable=false
internal.value.converter.schemas.enable=false
internal.key.converter=org.apache.kafka.connect.json.JsonConverter
internal.value.converter=org.apache.kafka.connect.json.JsonConverter
plugin.path=/app/hadoop/confluent/share/java
rest.port=8083

key.converter=org.apache.kafka.connect.storage.StringConverter
value.converter=org.apache.kafka.connect.converters.ByteArrayConverter

group.id=connector_test_grp1
config.storage.topic=connector_config_test_tpc1
offset.storage.topic=connector_offset_test_tpc1
status.storage.topic=connector_status_test_tpc1

bootstrap.servers=mybootstrap
EOF

#！！！手工，把beta环境的confluent打包通过跳板机放置到/tmp目录，注意：
  # share/java里的软链接替换为相应目录和文件
  # 删除config目录下所有文件
  # 删除etc/schema-registry/schema-registry.properties
  # 删除logs目录下所有文件
unzip ~/tmp/confluent-5.3.2.zip

file=~/mykc/confluent-5.3.2/etc/kafka/log4j.properties
cp ${file} ${file}.bk
sed -i 's@log4j.appender.kafkaAppender.File=${kafka.logs.dir}/server.log@log4j.appender.kafkaAppender.File=/opt/confluent/logs/server.log@g' ${file}

cat << \EOF > Dockerfile-conn.yaml
FROM anapsix/alpine-java:8_server-jre_unlimited
MAINTAINER bronzels@hotmail.com
USER root:root

RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

COPY confluent-5.3.2 /opt/confluent-5.3.2
RUN ln -sf /opt/confluent-5.3.2 /opt/confluent

WORKDIR /opt/confluent

CMD bin/connect-distributed /opt/confluent/config/connect-distributed.properties 2> /opt/confluent/logs/stderr.log > /opt/confluent/logs/stdout.log
EOF
#
#RUN echo $JAVA_HOME
#RUN java -version
#WORKDIR /opt/confluent
#RUN sed -i 's/\r$//' /opt/confluent/bin/connect-distributed  && \
#        chmod +x /opt/confluent/bin/connect-distributed

docker images|grep "<none>"|awk '{print $3}'|xargs docker rmi -f

docker images|grep mykc-conn
docker images|grep mykc-conn|awk '{print $3}'|xargs docker rmi -f
ansible slavek8s -i /etc/ansible/hosts-ubuntu -m shell -a"docker images|grep mykc-conn|awk '{print \$3}'|xargs docker rmi -f"
docker images|grep mykc-conn

docker build -f Dockerfile-conn.yaml -t master01:30500/bigdata/mykc-conn:0.1 ./
docker push master01:30500/bigdata/mykc-conn:0.1

#docker rmi master01:30500/bigdata/mykc-conn:0.1

:<<EOF
        livenessProbe:
          httpGet:
            path: /
            port: myconn
            scheme: HTTP
          initialDelaySeconds: 120
          timeoutSeconds: 2
EOF

cat << \EOF > ~/mykc/kafka-connect-template.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myconn
  namespace: mymqns
spec:
  replicas: 1
  selector:
    matchLabels:
      app: myconn
      role: kafka-connector
  template:
    metadata:
      labels:
        app: myconn
        role: kafka-connector
    spec:
      containers:
      - name: myconn
        image: master01:30500/bigdata/mykc-conn:0.1
        imagePullPolicy: Always
        ports:
        - name: myconn
          containerPort: 8083
        volumeMounts:
        - name: myconn-volm
          mountPath: /opt/confluent/config
      volumes:
        - name: myconn-volm
          configMap:
            name: myprop
            items:
            - key: myconn-type-
              path: connect-distributed.properties
---
apiVersion: v1
kind: Service
metadata:
  name: myconnsvc
  namespace: mymqns
spec:
  selector:
    app: myconn
    role: kafka-connector
  type: ClusterIP
  ports:
  - port: 8083
    targetPort: 8083
EOF


file=~/scripts/myconnector-cp-start-log-check.sh
rm -f ${file}
cat ~/scripts/k8s_funcs.sh > ${file}
cat << \EOF >> ${file}

ns=$1
echo "ns:${ns}"
name=$2
echo "name:${name}"

podnsname=${ns}-${name}
wait_pod_specific_log_line "${podnsname}" "myconn" "/opt/confluent/logs/stdout.log" "INFO Kafka Connect started" 900
funcrst=`echo $?`
if [ ${funcrst} -eq 0 ]; then
  echo "$podnsname connector log line is not detected and timeout"
  exit 1
fi

#kubectl get pod -n ${podnsname} | awk '{print $1}' | grep myconn | xargs -I CNAME  sh -c "kubectl exec -n ${podnsname} CNAME -- cat /opt/confluent/logs/stdout.log|grep 'INFO Kafka Connect started'"

EOF
chmod a+x ${file}

file=~/scripts/myconnector-cp-op.sh
rm -f ${file}
cat ~/scripts/k8s_funcs.sh > ${file}
cat << \EOF >> ${file}
#!/bin/bash


op=$1
echo "op:${op}"
ns=$2
echo "ns:${ns}"
#json/avro/bson
kind=$3
echo "kind:${kind}"
name=$4
echo "name:${name}"

podnsname=${ns}-${name}
podnsname=${podnsname//_/-}
echo "podnsname:${podnsname}"
myfile=~/mykc/kafka-connect-${podnsname}.yaml
echo "myfile:${myfile}"
cmvolm=myconn-type-${kind}
echo "cmvolm:${cmvolm}"
if [ -f "$myfile" ]; then
  echo "$myfile exists"
  rm -f ${myfile}
fi
cp ~/mykc/kafka-connect-template.yaml ${myfile}
sed -i "s@mymqns@${podnsname}@g" ${myfile}
sed -i "s@myconn-type-@${cmvolm}@g" ${myfile}
echo "$myfile is created"

if_namespace_exists "${podnsname}"
funcrst=`echo $?`
echo "line:$LINENO, funcrst:${funcrst}"
if [ ${funcrst} -eq 0 ]; then
  kubectl create namespace ${podnsname}
  echo "$podnsname namespace is created"
fi

if_resource_with_exactname_exists "${podnsname}" "configmap" "myprop"
funcrst=`echo $?`
echo "line:$LINENO, funcrst:${funcrst}"
if [ ${funcrst} -eq 0 ]; then
  echo "$podnsname configmap doesn't exists"
else
  kubectl delete configmap myprop -n ${podnsname}
  echo "$podnsname configmap is deleted"
fi

if_resource_with_exactname_exists "${podnsname}" "pod" "myconn"
funcrst=`echo $?`
echo "line:$LINENO, funcrst:${funcrst}"
if [ ${funcrst} -eq 0 ]; then
  echo "$podnsname connector pod doesn't exists"
else
  echo "remove $podnsname connector"
  kubectl delete -f $myfile -n ${podnsname} --wait=true
  #kubectl wait deployment/myconn --for=delete --timeout=300s -n ${podnsname}
  #pod0name=`kubectl get pod -o wide -n ${podnsname}|grep myconn | awk '{print $1}'`
  #until kubectl get pod ${pod0name} 2>&1 >/dev/null; do sleep 10; done
  wait_pod_deleted "${podnsname}" "myconn" 300
  funcrst=`echo $?`
  if [ ${funcrst} -eq 0 ]; then
    echo "$podnsname connector pod is not deleted"
    exit 1
  else
    echo "$podnsname connector pod is deleted"
  fi
fi

if [ $op == "stop" ]; then
  exit 0
fi

podnsname4topic=${podnsname//-/_}
nsbootstrap=mykafka.${ns}:9092
nssr=mysr-schema-registry.${ns}:8081
cp -f connect-distributed.properties.json connect-distributed.properties.json.${podnsname}
sed -i "s@test_grp1@${podnsname4topic}@g" connect-distributed.properties.json.${podnsname}
sed -i "s@test_tpc1@${podnsname4topic}@g" connect-distributed.properties.json.${podnsname}
sed -i "s@mybootstrap@${nsbootstrap}@g" connect-distributed.properties.json.${podnsname}
cp -f connect-distributed.properties.avro connect-distributed.properties.avro.${podnsname}
sed -i "s@test_grp1@${podnsname4topic}@g" connect-distributed.properties.avro.${podnsname}
sed -i "s@test_tpc1@${podnsname4topic}@g" connect-distributed.properties.avro.${podnsname}
sed -i "s@mybootstrap@${nsbootstrap}@g" connect-distributed.properties.avro.${podnsname}
sed -i "s@mysr-host-port@${nssr}@g" connect-distributed.properties.avro.${podnsname}
cp -f connect-distributed.properties.bson connect-distributed.properties.bson.${podnsname}
sed -i "s@test_grp1@${podnsname4topic}@g" connect-distributed.properties.bson.${podnsname}
sed -i "s@test_tpc1@${podnsname4topic}@g" connect-distributed.properties.bson.${podnsname}
sed -i "s@mybootstrap@${nsbootstrap}@g" connect-distributed.properties.bson.${podnsname}

kubectl create configmap myprop -n ${podnsname} \
  --from-file=myconn-type-json=$HOME/mykc/connect-distributed.properties.json.${podnsname} \
  --from-file=myconn-type-avro=$HOME/mykc/connect-distributed.properties.avro.${podnsname} \
  --from-file=myconn-type-bson=$HOME/mykc/connect-distributed.properties.bson.${podnsname}
#  --from-file=log4j=$HOME/mykc/log4j.properties
echo "$podnsname configmap is created"
kubectl get configmap myprop -n ${podnsname} -o yaml

echo "create $podnsname connector"
kubectl apply -f $myfile -n ${podnsname}
echo "wait $podnsname connector created by operator"
#kubectl wait deployment/myconn --for=condition=Ready --timeout=300s -n ${podnsname}
wait_pod_running "${podnsname}" "myconn" 1 300
funcrst=`echo $?`
if [ ${funcrst} -eq 0 ]; then
  echo "$podnsname connector pod is not running"
  exit 1
else
  ~/scripts/myconnector-cp-start-log-check.sh ${ns} ${name}
fi

#kubectl get pod -n ${podnsname} | awk '{print $1}' | grep myconn | xargs -I CNAME  sh -c "kubectl exec -n ${podnsname} CNAME -- cat /opt/confluent/logs/stdout.log|grep 'INFO Kafka Connect started'"

EOF
chmod a+x ${file}

~/scripts/myconnector-cp-op.sh start mqstr json mysqlsrctest
~/scripts/myconnector-cp-op.sh stop mqstr json mysqlsrctest
#kubectl delete -f ~/mykc/kafka-connect-mqstr-mysqlsrctest.yaml
#rm -f ~/mykc/kafka-connect-mqstr-mysqlsrctest.yaml

~/scripts/myconnector-cp-start-log-check.sh mqstr mysqlsrctest

:<<EOF
kubectl get pod -n mqstr-mysqlsrctest | grep myconn | awk '{print $1}'
kubectl get svc -n mqstr-mysqlsrctest | grep myconn
kubectl exec -it myconn-5fd6f987bc-kd4vz -n mqstr-mysqlsrctest bash
EOF

kubectl run curl-json -it --image=radial/busyboxplus:curl --restart=Never --rm -- curl myconnsvc.mqstr-mysqlsrctest:8083
