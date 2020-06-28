#如果是项目定制开发的流处理部分有修改
# 把k8sdeploy.sh打包生成k8sdeploy.tar.gz上传到master01，解压到home目录


cd ~/flinkdeploy

#如果依赖库没有更改，只是主程序修改，没必要执行以下步骤：
cp ~/k8sdeploy_dir/flink_com_libfiles.tar.gz ./

docker images|grep "<none>"|awk '{print $3}'|xargs docker rmi -f

docker images|grep flink
docker images|grep flink|awk '{print $3}'|xargs docker rmi -f
ansible slavek8s -i /etc/ansible/hosts-ubuntu -m shell -a"docker images|grep flink|awk '{print \$3}'|xargs docker rmi -f"
docker images|grep flink

docker build -f ~/pika/Dockerfile -t master01:30500/bronzels/flink:0.1 ./
docker push master01:30500/bronzels/flink:0.1

~/scripts/myflink-cp-op.sh restart
