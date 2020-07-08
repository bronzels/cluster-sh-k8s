cd

cd ~/hive
cd image

hiverev=3.1.2
wget -c https://archive.apache.org/dist/hive/hive-${hiverev}/apache-hive-${hiverev}-bin.tar.gz

wget -c https://cdn.mysql.com//archives/mysql-connector-java-5.1/mysql-connector-java-5.1.47.tar.gz
tar xzvf mysql-connector-java-5.1.47.tar.gz
cp mysql-connector-java-5.1.47/mysql-connector-java-5.1.47.jar mysql-connector-java.jar

docker images|grep "<none>"|awk '{print $3}'|xargs docker rmi -f

docker images|grep hive
docker images|grep hive|awk '{print $3}'|xargs docker rmi -f
docker images|grep hive
sudo ansible slavek8s -m shell -a"docker images|grep hive|awk '{print \$3}'|xargs docker rmi -f"
sudo ansible slavek8s -m shell -a"docker images|grep hive"

docker build --build-arg HIVEREV=3.1.2 -t master01:30500/bronzels/hive-ubu16ssh:0.1 ./
docker push master01:30500/bronzels/hive-ubu16ssh:0.1

git clone https://github.com/chenlein/database-tools.git
cd database-tools
file=build.gradle
cp ${file} ${file}.bk
sed -i "/    compile group: 'dm', name: 'Dm7JdbcDriver', version: '7.1', classifier: 'jdk17-20170808'/d" ${file}
sed -i "s@    compile group: 'mysql', name: 'mysql-connector-java', version: '5.1.46'@    compile group: 'mysql', name: 'mysql-connector-java', version: '5.1.47'@g" ${file}
gradle build
ls build/distributions/database-tools-1.0-SNAPSHOT.tar
cp build/distributions/database-tools-1.0-SNAPSHOT.tar ../

cd ~/hive/image

docker images|grep "<none>"|awk '{print $3}'|xargs docker rmi -f

docker images|grep database-tools
docker images|grep database-tools|awk '{print $3}'|xargs docker rmi -f
docker images|grep database-tools
sudo ansible slavek8s -m shell -a"docker images|grep database-tools|awk '{print \$3}'|xargs docker rmi -f"
sudo ansible slavek8s -m shell -a"docker images|grep database-tools"

docker build -f Dockerfile.dbtool -t master01:30500/bronzels/database-tools:1.0-SNAPSHOT ./
docker push master01:30500/bronzels/database-tools:1.0-SNAPSHOT

cd ~/hive
kubectl apply -n hadoop -f yaml/

:<<EOF
kubectl delete -n hadoop -f yaml/

kubectl describe pod -n hadoop `kubectl get pod -n hadoop | grep hive-serv | awk '{print $1}'`
kubectl logs -n hadoop `kubectl get pod -n hadoop | grep hive-serv | awk '{print $1}'`
kubectl exec -it -n hadoop `kubectl get pod -n hadoop | grep hive-serv | awk '{print $1}'` -- bash

kubectl get configmap hive-custom-config-cm-ext -n hadoop -o yaml

kubectl run test-myubussh -n hadoop -ti --image=praqma/network-multitool --rm=true --restart=Never -- bash
  telnet hive-service 9083
  telnet hive-service 10000

kubectl get pod -n hadoop -o wide
kubectl get pvc -n hadoop -o wide
kubectl get svc -n hadoop -o wide

EOF