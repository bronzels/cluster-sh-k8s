#pika
cd ~
rev=1.12.9
wget -c https://dl.google.com/go/go${rev}.linux-amd64.tar.gz
tar -xzf ~/go${rev}.linux-amd64.tar.gz

rm -rf pika
git clone https://github.com/Qihoo360/pika.git
cd ~/pika
git tag
git checkout pika_codis
cp -r pika pika.bk

file=conf/pika.conf
cp $file ${file}.bk
#sed -i 's@@@g'  $file
sed -i 's@thread-num : 1@thread-num : 6@g'  $file
sed -i 's@databases : 1@databases : 8@g'  $file
sed -i 's@log-path : ./log/@log-path : /data/log/@g'  $file
sed -i 's@db-path : ./db/@db-path : /data/db/@g'  $file
sed -i 's@dump-path : ./dump/@dump-path : /data/dump/@g'  $file
sed -i 's@db-sync-path : ./dbsync/@db-sync-path : /data/dbsync/@g'  $file

:<<EOF
file=Dockerfile
cp ${file} ${file}.bk
sed -i 's@https://mirrors.ustc.edu.cn/epel/epel-release-latest-7.noarch.rpm@http://mirrors.aliyun.com/epel/epel-release-latest-7.noarch.rpm@g' ${file}
sed -i 's@FROM centos:latest@FROM centos:7@g' ${file}
EOF

cp ~/source.list.ubuntu.16.04 source.list

cd ~/pika
file=Dockerfile
cp $file ${file}.bk
cat << \EOF > ${file}
FROM ubuntu:16.04
MAINTAINER bronzels <bronzels@hotmail.com>
USER root:root

ENV PIKA /pika
COPY pika /pika
RUN ls /pika

COPY ./source.list /etc/apt
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

EOF

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

cd ~/codis/kubernetes
find ~/codis/kubernetes -name "*.yaml" | xargs sed -i 's@image: codis-image@image: master01:30500/codis/codis-image:0.1@g'
find ~/codis/kubernetes -name "*.yaml"  | xargs grep "apps/v1beta1"
find ~/codis/kubernetes -name "*.yaml" | xargs sed -i 's@apps/v1beta1@apps/v1@g'
#./output/bin/pika -c ./conf/pika.conf
file=codis-server.yaml
sed -i 's@image: codis-image@image: master01:30500/pikadb/pika_codis:0.1@g' ${file}
sed -i 's@6379@9221@g' ${file}
sed -i 's@replicas: 4@replicas: 6@g' ${file}
sed -i 's@command: \["codis-server"\]@command: \["output/bin/pika"\]@g' ${file}
sed -i 's@args: \[@#args: \[@g' ${file}
#sed -i '/#args: \[/a\        workingDir: "/pika"' ${file}
sed -i '/#args: \[/a\        args: \["-c","conf\/pika.conf"\]' ${file}
sed -i '/  serviceName:/i\  selector:\n      matchLabels:\n        app: codis-server' ${file}
sed -i 's@codis-admin@/codisbin/codis-admin@g' ${file}
sed -i 's@imagePullPolicy: IfNotPresent@imagePullPolicy: Always@g' ${file}
#"/bin/sh", "-c",
#sed -i 's@"\/bin\/sh"\, "-c"\, @@g' ${file}
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
          storage: 256Gi
EOF

sed -i '/  serviceName:/i\  selector:\n      matchLabels:\n        app: zk' zookeeper/zookeeper.yaml
sed -i '/  serviceName:/i\  selector:\n      matchLabels:\n        app: codis-dashboard' codis-dashboard.yaml
sed -i '/  serviceName:/i\  selector:\n      matchLabels:\n        app: codis-ha' codis-ha.yaml

file=codis-service.yaml
sed -i 's@6379@9221@g' ${file}
cp ${file} ${file}.template

file=codis-proxy.yaml
sed -i 's@replicas: 2@replicas: 3@g' ${file}


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

file=start.sh
cat ~/scripts/k8s_funcs.sh > ${file}
cat << \EOF >> ${file}

codisns=$1

product_name="codis-test"
#product_auth="auth"
case "$2" in

### 清理原来codis遗留数据
cleanup)
    kubectl delete -n ${codisns} -f .
    wait_pod_deleted "${codisns}" "codis-dashboard" 300
    wait_pod_deleted "${codisns}" "codis-fe" 300
    wait_pod_deleted "${codisns}" "codis-ha" 300
    wait_pod_deleted "${codisns}" "codis-ha" 300
    wait_pod_deleted "${codisns}" "codis-proxy" 300
    wait_pod_deleted "${codisns}" "codis-server" 300
    kubectl delete -n ${codisns} -f zookeeper/
    wait_pod_deleted "${codisns}" "zk" 300
    #wait_pod_deleted "${codisns}" "" 300

    ;;

### 创建新的codis集群
buildup)
    kubectl delete -n ${codisns} -f .
    wait_pod_deleted "${codisns}" "codis-dashboard" 300
    wait_pod_deleted "${codisns}" "codis-fe" 300
    wait_pod_deleted "${codisns}" "codis-ha" 300
    wait_pod_deleted "${codisns}" "codis-ha" 300
    wait_pod_deleted "${codisns}" "codis-proxy" 300
    wait_pod_deleted "${codisns}" "codis-server" 300
    kubectl delete -n ${codisns} -f zookeeper/
    wait_pod_deleted "${codisns}" "zk" 300
    #wait_pod_deleted "${codisns}" "" 300

    echo "start create zookeeper cluster"
    kubectl create -n ${codisns} -f zookeeper/zookeeper-service.yaml
    kubectl create -n ${codisns} -f zookeeper/zookeeper.yaml
    #while [ $(kubectl get pods -n ${codisns} -l app=zk |grep Running |wc -l) != 3 ]; do sleep 1; done;
    wait_pod_running "${codisns}" "zk" 3 600
    echo "finish create zookeeper cluster"

    kubectl create -n ${codisns} -f codis-service.yaml
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
    ;;

### 扩容／缩容 codis proxy
scale-proxy)
    kubectl scale -n ${codisns} rc codis-proxy --replicas=$3
    ;;

### 扩容／[缩容] codis server
scale-server)
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
diff ${file} ../kubernetes.bk/${file}

#serv
#codis-service.yaml
file=codis-service.yaml
cp ${file}.template ${file}
#sed -i 's@nodePort: 31080@nodePort: 31080@g' ${file}

./start.sh serv cleanup
./start.sh serv buildup

ansible slave -m shell -a"docker images|grep pika"
ansible slave -m shell -a"docker ps -a|grep codis"
#kubectl exec -it codis-server-0 -n serv bash
#kubectl get pod -n serv | awk '{print $1}' | grep codis-server | xargs kubectl describe pod -n serv
#kubectl get pod -n serv | awk '{print $1}' | grep codis-server | xargs kubectl logs -n serv
#kubectl exec -it codis-server-0 -n serv  -- bash
###kubectl get pod -n serv | awk '{print $1}' | grep codis-server-0 | xargs -I CNAME  sh -c "kubectl exec -it CNAME -n serv  -- /bin/sh"

kubectl -n default run test-redis -ti --image=redis --rm=true --restart=Never -- redis-cli -h codis-proxy.serv -p 19000  set fool2 bar2
kubectl -n default run test-redis -ti --image=redis --rm=true --restart=Never -- redis-cli -h codis-proxy.serv -p 19000  get fool2

#serv
#codis-service.yaml
file=codis-service.yaml
cp ${file}.template ${file}
sed -i 's@nodePort: 31080@nodePort: 31081@g' ${file}

./start.sh servyat buildup
#./start.sh servyat cleanup

kubectl -n default run test-redis -ti --image=redis --rm=true --restart=Never -- redis-cli -h codis-proxy.servyat -p 19000  set fool4 bar4
kubectl -n default run test-redis -ti --image=redis --rm=true --restart=Never -- redis-cli -h codis-proxy.servyat -p 19000  get fool4

ansible slave -m shell -a"docker images|grep pika"
ansible slave -m shell -a"docker ps -a|grep codis"
