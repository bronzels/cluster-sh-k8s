#ubuntu
cd ~
wget -c http://apache.mirrors.hoobly.com/flink/flink-1.10.1/flink-1.10.1-bin-scala_2.11.tgz
tar xvf flink-1.10.1-bin-scala_2.11.tgz
ln -s flink-1.10.1 flink

git clone https://github.com/GoogleCloudPlatform/flink-on-k8s-operator.git

helm repo add flink-operator-repo https://googlecloudplatform.github.io/flink-on-k8s-operator/

folder=~/flink-on-k8s-operator/config/samples
cp -r ${folder} ${folder}.bk
cd ${folder}

file=flinkoperator_v1beta1_flinksessioncluster.yaml
sed -i 's@name: flink:1.8.2@name: flink:1.9.0@g' ${file}

kubectl create clusterrolebinding flink-operator-role --clusterrole=cluster-admin --serviceaccount=flink-operator-system:default
#kubectl delete clusterrolebinding flink-operator-role

helm install myflkop flink-operator-repo/flink-operator --set operatorImage.name=gcr.io/flink-operator/flink-operator
#helm delete myflkop
#After deploying the operator, you can verify CRD flinkclusters.flinkoperator.k8s.io has been created:
kubectl get crds | grep flinkclusters.flinkoperator.k8s.io
#View the details of the CRD:
kubectl describe crds/flinkclusters.flinkoperator.k8s.io
#Find out the deployment:
kubectl get deployments -n flink-operator-system
#Verify the operator Pod is up and running:
kubectl get pods -n flink-operator-system
#Check the operator logs:
kubectl logs -n flink-operator-system -l app=flink-operator --all-containers

:<<EOF
  -Dkubernetes.cluster-id=myflink \
  -Dtaskmanager.memory.process.size=40960m \
  -Dkubernetes.taskmanager.cpu=4 \
  -Dtaskmanager.numberOfTaskSlots=8 \
  -Dresourcemanager.taskmanager-timeout=3600000 \
  -Dkubernetes.service.exposed.type=NodePort \
  -Dkubernetes.container-start-command-template="%java% %classpath% %jvmmem% %jvmopts% %logging% %class% %args%" \
  -Dkubernetes.jobmanager.service-account=flink

  -Dkubernetes.cluster-id=myflink \
  -Dtaskmanager.memory.process.size=4096m \
  -Dkubernetes.taskmanager.cpu=2 \
  -Dtaskmanager.numberOfTaskSlots=4 \
  -Dresourcemanager.taskmanager-timeout=3600000
EOF

file=flinkoperator_v1beta1_flinksessioncluster.yaml
cp ~/flink-on-k8s-operator/config/samples.bk/${file} ${file}
sed -i '/    taskmanager.numberOfTaskSlots: "1"/i\    taskmanager.memory.process.size: "4096m"' ${file}
sed -i 's@    taskmanager.numberOfTaskSlots: "1"@    taskmanager.numberOfTaskSlots: "4"@g' ${file}

kubectl apply -f flinkoperator_v1beta1_flinksessioncluster.yaml
#kubectl delete -f flinkoperator_v1beta1_flinksessioncluster.yaml


file=Dockerfile.client
cp $file ${file}.bk
cat << \EOF > ${file}
FROM master01:30500/bronzels/ubu16ssh:0.1
MAINTAINER bronzels <bronzels@hotmail.com>
USER root:root

ENV FLINK /opt/flink
COPY flink-1.10.1 /opt/flink-1.10.1
RUN ln -s /opt/flink-1.10.1 /opt/flink

apt-get install -y openjdk-8-jdk

WORKDIR $FLINK
EOF

docker images|grep "<none>"|awk '{print $3}'|xargs docker rmi -f

docker images|grep flink_client
docker images|grep flink_client|awk '{print $3}'|xargs docker rmi -f
ansible slavek8s -i /etc/ansible/hosts-ubuntu -m shell -a"docker images|grep flink_client|awk '{print \$3}'|xargs docker rmi -f"
docker images|grep flink_client

#ENTRYPOINT ["/pika/entrypoint.sh"]
#CMD ["/pika/bin/pika", "-c", "/pika/conf/pika.conf"]
docker build -f ~/pika/Dockerfile.client -t master01:30500/bronzels/flink_client:0.1 $HOME
docker push master01:30500/bronzels/flink_client:0.1

cat <<EOF | kubectl apply --filename -
apiVersion: batch/v1
kind: Job
metadata:
  name: flink_client
spec:
  template:
    spec:
      containers:
      - name: flink_client
        image: master01:30500/bronzels/flink_client:0.1
        args:
        - /opt/flink/bin/flink
        - run
        - -m
        - flinksessioncluster-sample-jobmanager:8081
        - /opt/flink/examples/batch/WordCount.jar
        - --input
        - /opt/flink/README.txt
      restartPolicy: Never
EOF

file=~/scripts/myflink-cp-op.sh
rm -f ${file}
cat << \EOF > ${file}
#!/bin/bash
op=$1

if [ $op == "stop" ]; then
  echo 'stop' | ~/flink/bin/kubernetes-session.sh -Dkubernetes.cluster-id=myflink -Dexecution.attached=true
fi

if [ $op == "start" ]; then
  ~/flink/bin/kubernetes-session.sh \
    -Dkubernetes.cluster-id=myflink \
    -Dtaskmanager.memory.process.size=40960m \
    -Dkubernetes.taskmanager.cpu=4 \
    -Dtaskmanager.numberOfTaskSlots=8 \
    -Dresourcemanager.taskmanager-timeout=3600000 \
    -Dkubernetes.service.exposed.type=NodePort
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
