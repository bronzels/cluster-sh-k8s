#如果是项目定制开发contrib-connector有修改，把k8sdeploy.sh打包生成confluent_jars.tgz上传到跳板机/tmp
#如果是新的第三方connector，相应目录打包生成confluent_jars.tgz上传到跳板机/tmp
~/scripts/deploy_confluent_jars.sh

docker images|grep "<none>"|awk '{print $3}'|xargs docker rmi -f

docker images|grep mykc-conn
docker images|grep mykc-conn|awk '{print $3}'|xargs docker rmi -f
ansible slavek8s -i /etc/ansible/hosts-ubuntu -m shell -a"docker images|grep mykc-conn|awk '{print \$3}'|xargs docker rmi -f"
docker images|grep mykc-conn

docker build -f Dockerfile-conn.yaml -t master01:30500/bigdata/mykc-conn:0.1 ./
docker push master01:30500/bigdata/mykc-conn:0.1
