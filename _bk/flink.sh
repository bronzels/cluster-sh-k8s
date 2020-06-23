#ubuntu
cd ~
wget -c http://apache.mirrors.hoobly.com/flink/flink-1.10.1/flink-1.10.1-bin-scala_2.11.tgz
tar xvf flink-1.10.1-bin-scala_2.11.tgz
ln -s flink-1.10.1 flink

file=flink/conf/log4j.properties
cp ${file} ${file}.bk
sed -i 's@log4j.rootLogger=INFO, file@log4j.rootLogger=INFO, file, console@g' ${file}

cat << \EOF >> ${file}

# Log all infos to the console
log4j.appender.console=org.apache.log4j.ConsoleAppender
log4j.appender.console.layout=org.apache.log4j.PatternLayout
log4j.appender.console.layout.ConversionPattern=%d{yyyy-MM-dd HH:mm:ss,SSS} %-5p %-60c %x - %m%n
EOF

kubectl create serviceaccount flink
kubectl create clusterrolebinding flink-role-binding-flink --clusterrole=edit --serviceaccount=default:flink

file=~/scripts/myflink-cp-op.sh
rm -f ${file}
cat << \EOF > ${file}
#!/bin/bash
op=$1

cd ~/flink
if [ $op == "stop" ]; then
  echo 'stop' | bin/kubernetes-session.sh -Dkubernetes.cluster-id=myflink -Dexecution.attached=true
fi

if [ $op == "start" ]; then
  bin/kubernetes-session.sh \
    -Dkubernetes.cluster-id=myflink \
    -Dtaskmanager.memory.process.size=40960m \
    -Dkubernetes.taskmanager.cpu=4 \
    -Dtaskmanager.numberOfTaskSlots=8 \
    -Dresourcemanager.taskmanager-timeout=3600000 \
    -Dkubernetes.service.exposed.type=NodePort \
    -Dkubernetes.container-start-command-template="%java% %classpath% %jvmmem% %jvmopts% %logging% %class% %args%" \
    -Dkubernetes.jobmanager.service-account=flink
fi
EOF
chmod a+x ${file}

~/scripts/myflink-cp-op.sh start
~/scripts/myflink-cp-op.sh stop

./bin/kubernetes-session.sh \
  -Dkubernetes.cluster-id=myflink \
  -Dtaskmanager.memory.process.size=4096m \
  -Dkubernetes.taskmanager.cpu=2 \
  -Dtaskmanager.numberOfTaskSlots=4 \
  -Dresourcemanager.taskmanager-timeout=3600000

kubectl get pod | grep myflink
#检查得到Jobmanager ui的NodePort
kubectl get svc | grep myflink
