cd ~

MYHOME=$HOME/flinkdeploy
rm -rf ${MYHOME}
mkdir ${MYHOME}

cp ~/k8sdeploy_dir/str_jar ${MYHOME}
cp ~/scripts/startfmstrall.sh ${MYHOME}/str_jar

cd ${MYHOME}

rev=1.10.1
wget -c http://apache.mirrors.hoobly.com/flink/flink-${rev}/flink-${rev}-bin-scala_2.11.tgz
rm -rf flink-${rev}
tar xvf flink-${rev}-bin-scala_2.11.tgz

file=${rev}/conf/flink-conf.yaml
sed -i 's@jobmanager.rpc.address: localhost@jobmanager.rpc.address: flink-jm-rpc-service@g' ${file}
sed -i 's@jobmanager.heap.size: 1024m@jobmanager.heap.size: 24576m@g' ${file}
sed -i 's@taskmanager.memory.process.size: 1728m@taskmanager.memory.process.size: 40960m@g' ${file}
sed -i 's@taskmanager.numberOfTaskSlots: 1@taskmanager.numberOfTaskSlots: 8@g' ${file}

file=flink/conf/log4j.properties
cp ${file} ${file}.bk
sed -i 's@log4j.rootLogger=INFO, file@log4j.rootLogger=INFO, file, console@g' ${file}

cat << \EOF >> ${file}

# Log all infos to the console
log4j.appender.console=org.apache.log4j.ConsoleAppender
log4j.appender.console.layout=org.apache.log4j.PatternLayout
log4j.appender.console.layout.ConversionPattern=%d{yyyy-MM-dd HH:mm:ss,SSS} %-5p %-60c %x - %m%n
EOF

docker images|grep "<none>"|awk '{print $3}'|xargs docker rmi -f

docker images|grep flink
docker images|grep flink|awk '{print $3}'|xargs docker rmi -f
ansible slavek8s -i /etc/ansible/hosts-ubuntu -m shell -a"docker images|grep flink|awk '{print \$3}'|xargs docker rmi -f"
docker images|grep flink

file=flink-job-manager-deployment.yaml
cp ${file} ${file}.bk
sed -i 's@imagePullPolicy: IfNotPresent@imagePullPolicy: Always@g' ${file}
file=flink-task-manager-statefulset.yaml
cp ${file} ${file}.bk
sed -i 's@imagePullPolicy: IfNotPresent@imagePullPolicy: Always@g' ${file}

docker build -f ~/pika/Dockerfile.client -t master01:30500/bronzels/flink:0.1 ./
docker push master01:30500/bronzels/flink:0.1

FLINKNS=flk

cd ~/flinkdeploy
file=~/scripts/myflink-cp-op.sh
cat << EOF > ${file}
if [ $op == "stop" ]; then
  kubectl delete -f ${MYHOME}/yaml/
  wait_pod_deleted "$FLINKNS" "flink-jobmanager" 300
  wait_pod_deleted "$FLINKNS" "flink-taskmanager" 300
fi

if [ $op == "start" ]; then
  kubectl apply -f ${MYHOME}/yaml/
  wait_pod_running "$FLINKNS" "flink-jobmanager" 300
  wait_pod_running "$FLINKNS" "flink-taskmanager" 300
fi

EOF
sed -i 's@FLINKNS@"${FLINKNS}"@g' ${file}
chmod a+x ${file}

~/scripts/myflink-cp-op.sh start
curl localhost:30123
ssh

~/scripts/myflink-cp-op.sh start

