cd ~

MYHOME=$HOME/str

cd ${MYHOME}/image

cp -rfv ~/k8sdeploy_dir/str_jar ./
cp -v ~/k8sdeploy_dir/flink_com_libfiles.tar.gz ./
rm -rf scripts
mkdir scripts
cp -v ~/scripts/startfmstrall.sh scripts/

rev=1.10.1
wget -c http://apache.mirrors.hoobly.com/flink/flink-${rev}/flink-${rev}-bin-scala_2.11.tgz
rm -rf flink-${rev}
tar xvf flink-${rev}-bin-scala_2.11.tgz

file=flink-${rev}/conf/flink-conf.yaml
cp ${file} ${file}.bk
sed -i 's@jobmanager.rpc.address: localhost@jobmanager.rpc.address: flink-jm-rpc-service@g' ${file}
sed -i 's@jobmanager.heap.size: 1024m@jobmanager.heap.size: 24576m@g' ${file}
sed -i 's@taskmanager.memory.process.size: 1728m@#taskmanager.memory.process.size: 1728m@g' ${file}
sed -i 's@# taskmanager.memory.flink.size: 1280m@taskmanager.memory.flink.size: 53248m@g' ${file}
sed -i 's@taskmanager.numberOfTaskSlots: 1@taskmanager.numberOfTaskSlots: 8@g' ${file}

file=flink-${rev}/conf/log4j.properties
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

docker build -t master01:30500/bronzels/flink:0.1 ./
docker push master01:30500/bronzels/flink:0.1

cd ${MYHOME}/yaml

file=flink-job-manager-deployment.yaml
cp ${file} ${file}.bk
sed -i 's@imagePullPolicy: IfNotPresent@imagePullPolicy: Always@g' ${file}
file=flink-task-manager-statefulset.yaml
cp ${file} ${file}.bk
sed -i 's@imagePullPolicy: IfNotPresent@imagePullPolicy: Always@g' ${file}

file=~/scripts/myflink-cp-op.sh
cat << \EOF > ${file}
#!/bin/bash

. ${HOME}/scripts/k8s_funcs.sh

op=$1
echo "op:${op}"

cd ~/str

if [ $op == "stop" -o $op == "restart" ]; then
  kubectl delete -n str -f yaml/
  wait_pod_deleted "str" "flink-taskmanager" 300
  wait_pod_deleted "str" "flink-jobmanager" 300
fi

if [ $op == "start" -o $op == "restart" ]; then
  kubectl apply -n str -f yaml/
  wait_pod_running "str" "flink-taskmanager" 3 300
  wait_pod_running "str" "flink-jobmanager" 1 300
fi

EOF
chmod a+x ${file}

~/scripts/myflink-cp-op.sh start
~/scripts/myflink-cp-op.sh stop
~/scripts/myflink-cp-op.sh restart

:<<EOF
kubectl get pod -n str
kubectl get svc -n str

curl localhost:30123

kubectl exec -it -n str `kubectl get pod -n str | grep flink-jobmanager | awk '{print $1}'` -- ls -l /opt/scripts
kubectl exec -it -n str `kubectl get pod -n str | grep flink-jobmanager | awk '{print $1}'` -- ls /opt/flink/lib
kubectl exec -it -n str `kubectl get pod -n str | grep flink-jobmanager | awk '{print $1}'` -- ls /opt/str_jar

kubectl run test-myubussh-str -ti --image=praqma/network-multitool --rm=true --restart=Never -- bash
  ssh -p 22 root@flink-ssh-service.str

    /opt/flink/bin/flink run -d -m 127.0.0.1:8081 /opt/flink/examples/streaming/WindowJoin.jar

EOF


