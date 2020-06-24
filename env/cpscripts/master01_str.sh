#如果是项目定制开发的流处理部分有修改，把k8sdeploy.sh打包生成k8sdeploy.tar.gz上传到跳板机
#ubuntu
cd ~

tar xzvf /tmp/k8sdeploy.tar.gz

cd ~/flinkdeploy

docker images|grep "<none>"|awk '{print $3}'|xargs docker rmi -f

docker images|grep flink
docker images|grep flink|awk '{print $3}'|xargs docker rmi -f
ansible slavek8s -i /etc/ansible/hosts-ubuntu -m shell -a"docker images|grep flink|awk '{print \$3}'|xargs docker rmi -f"
docker images|grep flink

cp -rf ~/k8sdeploy_dir/str_jar ~/flinkdeploy/str_jar

docker build -f ~/pika/Dockerfile -t master01:30500/bronzels/flink:0.1 ./
docker push master01:30500/bronzels/flink:0.1
