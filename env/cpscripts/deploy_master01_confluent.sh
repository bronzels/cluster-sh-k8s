#如果是项目定制开发contrib-connector有修改
#把k8sdeploy.sh打包生成k8sdeploy.tar.gz上传到master01，解压到home目录

rev=5.3.2
destdir=${HOME}/mykc/confluent-${rev}/share/java
cd ${destdir}
rm -rf kafka-connect-contrib

tar xzvf /tmp/confluent_jars.tgz

docker images|grep "<none>"|awk '{print $3}'|xargs docker rmi -f

docker images|grep mykc-conn
docker images|grep mykc-conn|awk '{print $3}'|xargs docker rmi -f
ansible slavek8s -i /etc/ansible/hosts-ubuntu -m shell -a"docker images|grep mykc-conn|awk '{print \$3}'|xargs docker rmi -f"
docker images|grep mykc-conn

docker build -f Dockerfile-conn.yaml -t master01:30500/bigdata/mykc-conn:0.1 ./
docker push master01:30500/bigdata/mykc-conn:0.1
