#pika
cd ~
rm -rf pika
git clone https://github.com/Qihoo360/pika.git
cd ~/pika
git checkout pika_codis
cd ~
cp -r pika pika.bk

cd ~/pika
file=conf/pika.conf
cp $file ${file}.bk
#sed -i 's@@@g'  $file
sed -i 's@thread-num : 1@thread-num : 6@g'  $file
sed -i 's@databases : 1@databases : 8@g'  $file
sed -i 's@log-path : ./log/@log-path : /data/log/@g'  $file
sed -i 's@db-path : ./db/@db-path : /data/db/@g'  $file
sed -i 's@dump-path : ./dump/@dump-path : /data/dump/@g'  $file
sed -i 's@db-sync-path : ./dbsync/@db-sync-path : /data/dbsync/@g'  $file

cd ~
cp ~/sources.list.ubuntu.16.04 sources.list
COPY ./sources.list /etc/apt

cd ~/pika
file=Dockerfile
cp $file ${file}.bk
cat << \EOF > ${file}
FROM ubuntu:16.04
MAINTAINER bronzels <bronzels@hotmail.com>
USER root:root

ENV PIKA /pika
COPY pika /pika
COPY sources.list /etc/apt

RUN apt-get update && \
    apt-get install -y build-essential git autoconf

RUN apt-get install -y libzip-dev libsnappy-dev libprotobuf-dev protobuf-compiler bzip2 && \
    apt-get install -y libgoogle-glog-dev

WORKDIR $PIKA
RUN make
ENV PATH ${PIKA}/output/bin:${PATH}

COPY go /go
ENV PATH /go/bin:${PATH}
RUN mkdir /gopath
ENV GOPATH /gopath
RUN mkdir -p /gopath/src/github.com/CodisLabs
WORKDIR /gopath/src/github.com/CodisLabs
RUN git clone https://github.com/CodisLabs/codis.git -b release3.2
ENV CODIS /gopath/src/github.com/CodisLabs/codis
WORKDIR ${CODIS}
RUN make
ENV PATH ${CODIS}/bin:${PATH}

WORKDIR $PIKA
EOF

docker images|grep "<none>"|awk '{print $3}'|xargs docker rmi -f

docker images|grep pika_codis
docker images|grep pika_codis|awk '{print $3}'|xargs docker rmi -f
ansible slavek8s -i /etc/ansible/hosts-ubuntu -m shell -a"docker images|grep pika_codis|awk '{print \$3}'|xargs docker rmi -f"
docker images|grep pika_codis

#ENTRYPOINT ["/pika/entrypoint.sh"]
#CMD ["/pika/bin/pika", "-c", "/pika/conf/pika.conf"]
docker build -f ~/pika/Dockerfile -t master01:30500/pikadb/pika_codis:0.1 $HOME
docker push master01:30500/pikadb/pika_codis:0.1

#codis
cd ~
git clone https://github.com/CodisLabs/codis.git -b release3.2
cd ~/codis
cp -r kubernetes kubernetes.bk

docker build -t master01:30500/codis/codis-image:0.1 ./
docker push master01:30500/codis/codis-image:0.1

find ~/codis/kubernetes -name "*.yaml" | xargs grep "image: codis-image"
find ~/codis/kubernetes -name "*.yaml" | xargs sed -i 's@image: codis-image@image: master01:30500/codis/codis-image:0.1@g'
find ~/codis/kubernetes -name "*.yaml"  | xargs grep "apps/v1beta1"
find ~/codis/kubernetes -name "*.yaml" | xargs sed -i 's@apps/v1beta1@apps/v1@g'

cd ~/codis/kubernetes
file=codis-server.yaml
cp ~/codis/kubernetes.bk/$file $file
#./output/bin/pika -c ./conf/pika.conf
sed -i 's@image: codis-image@image: master01:30500/pikadb/pika_codis:0.1@g' ${file}
sed -i 's@6379@9221@g' ${file}
sed -i 's@replicas: 4@replicas: 6@g' ${file}
sed -i 's@command: \["codis-server"\]@command: \["output\/bin\/pika"\]@g' ${file}
sed -i 's@args: \[@#args: \[@g' ${file}
#sed -i '/#args: \[/a\        workingDir: "/pika"' ${file}
sed -i '/#args: \[/a\        args: \["-c","\/pika\/conf\/pika.conf"\]' ${file}
sed -i '/  serviceName:/i\  selector:\n      matchLabels:\n        app: codis-server' ${file}
#sed -i 's@codis-admin@/codisbin/codis-admin@g' ${file}
sed -i 's@imagePullPolicy: IfNotPresent@imagePullPolicy: Always@g' ${file}
sed -i 's@apps/v1beta1@apps/v1@g' ${file}
cat << \EOF >> ${file}
        volumeMounts:
        - name: datadir
          mountPath: /data
  volumeClaimTemplates:
  - metadata:
      name: datadir
      annotations:
        volume.beta.kubernetes.io/storage-class: rook-ceph-block
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 128Gi
EOF

sed -i '/  serviceName:/i\  selector:\n      matchLabels:\n        app: zk' zookeeper/zookeeper.yaml
sed -i '/  serviceName:/i\  selector:\n      matchLabels:\n        app: codis-dashboard' codis-dashboard.yaml
sed -i '/  serviceName:/i\  selector:\n      matchLabels:\n        app: codis-ha' codis-ha.yaml

file=codis-service.yaml
cp ~/codis/kubernetes.bk/$file $file
sed -i 's@6379@9221@g' ${file}
cat << \EOF >> ${file}

---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: codis-proxy
  name: codis-proxy-ext
spec:
  type: NodePort
  ports:
  - port: 19000
    name: proxy
    nodePort: 31900
  selector:
    app: codis-proxy
EOF
mv ${file} ${file}.template

file=codis-proxy.yaml
sed -i 's@replicas: 2@replicas: 3@g' ${file}

find ~/codis/kubernetes -name "*.yaml" | xargs grep 'value: "codis-test"'
find ~/codis/kubernetes -name "*.yaml" | xargs sed -i 's@value: \"codis-test\"@value: \"str\"@g'

:<<EOF
file=start.sh
cp ${file} ${file}.bk
sed -i 's@\$3@\$4@g' ${file}
sed -i 's@\$2@\$3@g' ${file}
sed -i 's@\$1@\$2@g' ${file}
sed -i '/\#!\/bin\/bash/ a\codisns=$1' ${file}
sed -i 's@kubectl get pods@kubectl get pods -n \${codisns}@g' ${file}
sed -i 's@kubectl create -f@kubectl create -n \${codisns} -f@g' ${file}
sed -i 's@kubectl get statefulset@kubectl get statefulset -n \${codisns}@g' ${file}
sed -i 's@kubectl delete@kubectl delete -n \${codisns}@g' ${file}
sed -i 's@kubectl exec@kubectl exec -n \${codisns}@g' ${file}
sed -i 's@kubectl scale@kubectl scale -n \${codisns}@g' ${file}
EOF

file=~/scripts/mycodis-cp-op.sh
rm -f ${file}
#cat ~/scripts/k8s_funcs.sh > ${file}
cat << \EOF > ${file}
#!/bin/bash

. ${HOME}/scripts/k8s_funcs.sh

#set -e

op=$1
echo "op:${op}"
codisns=$2
echo "codisns:${codisns}"

cd ~/codis/kubernetes

#serv
#codis-service.yaml
file=codis-service
cp ${file}.yaml.template ${file}-${codisns}.yaml
if [ $codisns == "serv" ]; then
  echo "in serv"
  #sed -i 's@nodePort: 31080@nodePort: 31080@g' ${file}-${codisns}.yaml
  #sed -i 's@nodePort: 31900@nodePort: 31900@g' ${file}-${codisns}.yaml
else
  echo "in servyat"
  sed -i 's@nodePort: 31080@nodePort: 31081@g' ${file}-${codisns}.yaml
  sed -i 's@nodePort: 31900@nodePort: 31901@g' ${file}-${codisns}.yaml
fi

function mycodis_cp_op_stop(){
  echo "now in mycodis_cp_op_stop"
  kubectl delete -n ${codisns} -f codis-fe.yaml
  wait_pod_deleted "${codisns}" "codis-fe" 300
  kubectl delete -n ${codisns} -f codis-dashboard.yaml
  wait_pod_deleted "${codisns}" "codis-dashboard" 300
  kubectl delete -n ${codisns} -f codis-ha.yaml
  wait_pod_deleted "${codisns}" "codis-ha" 300
  kubectl delete -n ${codisns} -f codis-proxy.yaml
  wait_pod_deleted "${codisns}" "codis-proxy" 300
  kubectl delete -n ${codisns} -f codis-server.yaml
  wait_pod_deleted "${codisns}" "codis-server" 300
  kubectl delete -n ${codisns} -f codis-service-${codisns}.yaml
  echo "now before zookeeper del"
  kubectl delete -n ${codisns} -f zookeeper/
  echo "now after zookeeper del"
  wait_pod_deleted "${codisns}" "zk" 300
  #wait_pod_deleted "${codisns}" "" 300
}

function mycodis_cp_op_deletepvc(){
  echo "now in mycodis_cp_op_deletepvc"
  kubectl get pvc -n ${codisns} | grep codis-server | awk '{print $1}' | xargs kubectl -n ${codisns} delete pvc
}

function mycodis_cp_op_start(){
  echo "now in mycodis_cp_op_start"
  echo "start create zookeeper cluster"
  kubectl create -n ${codisns} -f zookeeper/zookeeper-service.yaml
  kubectl create -n ${codisns} -f zookeeper/zookeeper.yaml
  #while [ $(kubectl get pods -n ${codisns} -l app=zk |grep Running |wc -l) != 3 ]; do sleep 1; done;
  wait_pod_running "${codisns}" "zk" 3 600
  echo "finish create zookeeper cluster"

  kubectl create -n ${codisns} -f codis-service-${codisns}.yaml
  kubectl create -n ${codisns} -f codis-dashboard.yaml
  #while [ $(kubectl get pods -n ${codisns} -l app=codis-dashboard |grep Running |wc -l) != 1 ]; do sleep 1; done;
  wait_pod_running "${codisns}" "codis-dashboard" 1 600
  kubectl create -n ${codisns} -f codis-proxy.yaml
  kubectl create -n ${codisns} -f codis-server.yaml
  servers=$(grep "replicas" codis-server.yaml |awk  '{print $2}')
  #while [ $(kubectl get pods -n ${codisns} -l app=codis-server |grep Running |wc -l) != $servers ]; do sleep 1; done;
  wait_pod_running "${codisns}" "codis-server" $servers 600
  kubectl exec -n ${codisns} -it codis-server-0 -- codis-admin  --dashboard=codis-dashboard:18080 --rebalance --confirm
  kubectl create -n ${codisns} -f codis-ha.yaml
  kubectl create -n ${codisns} -f codis-fe.yaml
  sleep 60
  sleep 60
  kubectl exec -n ${codisns} -it codis-dashboard-0 -- redis-cli -h codis-proxy -p 19000 PING
  if [ $? != 0 ]; then
      echo "buildup codis cluster with problems, plz check it!!"
  fi
}

case "$op" in

### 停止codis集群
stop)
    echo "now in stop"
    mycodis_cp_op_stop

    ;;

### 停止codis集群，并且清理原来codis遗留数据
clean)
    echo "now in clean"
    mycodis_cp_op_stop
    mycodis_cp_op_deletepvc

    ;;

### 创建新的codis集群
startnew)
    echo "now in startnew"
    mycodis_cp_op_stop
    mycodis_cp_op_deletepvc
    mycodis_cp_op_start

    ;;

### 启动codis集群
start)
    echo "now in start"
    mycodis_cp_op_start

    ;;

### 重启codis集群
restart)
    echo "now in restart"
    mycodis_cp_op_stop
    mycodis_cp_op_start

    ;;

### 扩容／缩容 codis proxy
scale-proxy)
    echo "now in scale-proxy"
    kubectl scale -n ${codisns} rc codis-proxy --replicas=$3
    ;;

### 扩容／[缩容] codis server
scale-server)
    echo "now in scale-server"
    cur=$(kubectl get statefulset -n ${codisns} codis-server |tail -n 1 |awk '{print $4}')
    des=$3
    echo $cur
    echo $des
    if [ $cur == $des ]; then
        echo "current server == desired server, return"
    elif [ $cur -lt $des ]; then
        kubectl scale -n ${codisns} statefulsets codis-server --replicas=$des
        #while [ $(kubectl get pods -n ${codisns} -l app=codis-server |grep Running |wc -l) != $3 ]; do sleep 1; done;
        wait_pod_running "${codisns}" "codis-server" 3 600
        kubectl exec -n ${codisns} -it codis-server-0 -- codis-admin  --dashboard=codis-dashboard:18080 --rebalance --confirm
    else
        echo "reduce the number of codis-server, does not support, please wait"
        # while [ $cur > $des ]
        # do
        #    cur=`expr $cur - 2`
        #    gid=$(expr $cur / 2 + 1)
        #    kubectl exec -n ${codisns} -it codis-server-0 -- codis-admin  --dashboard=codis-dashboard:18080 --slot-action --create-some --gid-from=$gid --gid-to=1 --num-slots=1024
        #    while [ $(kubectl exec -n ${codisns} -it codis-server-0 -- codis-admin  --dashboard=codis-dashboard:18080  --slots-status |grep "\"backend_addr_group_id\": $gid" |wc -l) != 0 ]; do echo "waiting slot migrating..."; sleep 1; done;
        #    kubectl scale -n ${codisns} statefulsets codis-server --replicas=$cur
        #    kubectl exec -n ${codisns} -it codis-server-0 -- codis-admin  --dashboard=codis-dashboard:18080 --remove-group --gid=$gid
        # done
        # kubectl scale -n ${codisns} statefulsets codis-server --replicas=$des
        # kubectl exec -n ${codisns} -it codis-server-0 -- codis-admin  --dashboard=codis-dashboard:18080 --rebalance --confirm
    fi
    ;;

*)
    echo "wrong argument(s)"
    ;;

esac
EOF
chmod a+x ${file}
diff ${file} ../kubernetes.bk/start.sh

cd ~/codis/kubernetes
~/scripts/mycodis-cp-op.sh start serv
~/scripts/mycodis-cp-op.sh stop serv
~/scripts/mycodis-cp-op.sh restart serv
#kubectl get pvc -n serv | awk '{print $1}' | grep datadir-codis-server | xargs kubectl delete pvc -n serv

curl http://master01:31080

kubectl -n default run test-redis -ti --image=redis --rm=true --restart=Never -- redis-cli -h codis-proxy.serv -p 19000  set fool2 bar2
kubectl -n default run test-redis -ti --image=redis --rm=true --restart=Never -- redis-cli -h codis-proxy.serv -p 19000  get fool2
kubectl -n default run test-zookeeper-serv -ti --image=zookeeper:3.5.5 --rm=true --restart=Never -- zkCli.sh -server zookeeper.serv:2181 ls /codis3/str
kubectl -n default run test-redis -ti --image=redis --rm=true --restart=Never -- redis-cli -h 10.10.0.234 -p 31900  set fool3 bar3
kubectl -n default run test-redis -ti --image=redis --rm=true --restart=Never -- redis-cli -h 10.10.0.234 -p 31900  get fool3

cd ~/codis/kubernetes
~/scripts/mycodis-cp-op.sh start servyat
~/scripts/mycodis-cp-op.sh stop servyat
~/scripts/mycodis-cp-op.sh restart servyat
#kubectl get pvc -n servyat | awk '{print $1}' | grep datadir-codis-server | xargs kubectl delete pvc -n servyat
curl http://master01:31081

kubectl -n default run test-redis -ti --image=redis --rm=true --restart=Never -- redis-cli -h codis-proxy.servyat -p 19000  set fool4 bar4
kubectl -n default run test-redis -ti --image=redis --rm=true --restart=Never -- redis-cli -h codis-proxy.servyat -p 19000  get fool4
kubectl -n default run test-zookeeper-serv -ti --image=zookeeper:3.5.5 --rm=true --restart=Never -- zkCli.sh -server zookeeper.servyat:2181 ls /codis3/str
kubectl -n default run test-redis -ti --image=redis --rm=true --restart=Never -- redis-cli -h 10.10.0.234 -p 31901  set fool5 bar5
kubectl -n default run test-redis -ti --image=redis --rm=true --restart=Never -- redis-cli -h 10.10.0.234 -p 31901  get fool5

:<<EOF
kubectl exec -it codis-server-0 -n serv bash
kubectl get pod -n serv | awk '{print $1}' | grep codis-server | xargs kubectl describe pod -n serv
kubectl get pod -n serv | awk '{print $1}' | grep codis-server | xargs kubectl logs -n serv
kubectl exec -it codis-server-0 -n serv  -- bash
  kubectl get pod -n serv | awk '{print $1}' | grep codis-server-0 | xargs -I CNAME  sh -c "kubectl exec -it CNAME -n serv  -- /bin/sh"

kubectl get pod -n serv
kubectl get pvc -n serv
kubectl get svc -n serv

EOF
