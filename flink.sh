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

rm -rf ~/flinkdeploy
mkdir ~/flinkdeploy
cd ~/flinkdeploy
cp ~/k8sdeploy_dir/flink_com_libfiles.tar.gz

file=Dockerfile
cat << \EOF >> ${file}
FROM flink:latest
MAINTAINER bronzels <bronzels@hotmail.com>

ADD flink_com_libfiles.tar.gz /opt/flink/lib
EOF

docker images|grep "<none>"|awk '{print $3}'|xargs docker rmi -f

docker images|grep flink
docker images|grep flink|awk '{print $3}'|xargs docker rmi -f
ansible slavek8s -i /etc/ansible/hosts-ubuntu -m shell -a"docker images|grep flink|awk '{print \$3}'|xargs docker rmi -f"
docker images|grep flink

docker build -f ~/pika/Dockerfile -t master01:30500/bronzels/flink:0.1 ./
docker push master01:30500/bronzels/flink:0.1

#    -Dkubernetes.namespace=str
file=~/scripts/myflink-cp-op.sh
rm -f ${file}
cat << \EOF > ${file}
#!/bin/bash

. ${HOME}/scripts/k8s_funcs.sh

op=$1
echo "op:${op}"

cd ~/flink
if [ $op == "stop" -o $op == "restart" ]; then
  echo 'stop' | bin/kubernetes-session.sh -Dkubernetes.cluster-id=myflink -Dexecution.attached=true
  wait_pod_deleted "default" "myflink" 300
fi

if [ $op == "start" -o $op == "restart" ]; then
  bin/kubernetes-session.sh \
    -Dkubernetes.container.image=master01:30500/bronzels/flink:0.1
    -Dkubernetes.cluster-id=myflink \
    -Dtaskmanager.memory.process.size=40960m \
    -Dkubernetes.taskmanager.cpu=4 \
    -Dtaskmanager.numberOfTaskSlots=8 \
    -Dresourcemanager.taskmanager-timeout=3600000 \
    -Dkubernetes.service.exposed.type=NodePort \
    -Dkubernetes.container-start-command-template="%java% %classpath% %jvmmem% %jvmopts% %logging% %class% %args%" \
    -Dkubernetes.jobmanager.service-account=flink \
    -Dcontainerized.master.env.HTTP2_DISABLE=true \
    -Dcontainerized.taskmanager.env.HTTP2_DISABLE=true
  wait_pod_running "default" "myflink" 1
fi
EOF
chmod a+x ${file}

~/scripts/myflink-cp-op.sh start
~/scripts/myflink-cp-op.sh stop
~/scripts/myflink-cp-op.sh restart

kubectl get pod | grep myflink
#检查得到Jobmanager ui的NodePort
kubectl get svc | grep myflink

cd ~/flink
bin/flink run -d -e kubernetes-session -Dkubernetes.cluster-id=myflink examples/streaming/WindowJoin.jar
