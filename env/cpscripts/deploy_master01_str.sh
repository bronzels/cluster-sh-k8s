#如果是项目定制开发的流处理部分有修改
# 把k8sdeploy.sh打包生成k8sdeploy.tar.gz上传到master01，解压到home目录


cd ~/flinkdeploy

#如果依赖库没有更改，只是主程序修改，可以跳过image building和flink重启
cp ~/k8sdeploy_dir/flink_com_libfiles.tar.gz ./

docker images|grep "<none>"|awk '{print $3}'|xargs docker rmi -f

docker images|grep flink
docker images|grep flink|awk '{print $3}'|xargs docker rmi -f
ansible slavek8s -i /etc/ansible/hosts-ubuntu -m shell -a"docker images|grep flink|awk '{print \$3}'|xargs docker rmi -f"
docker images|grep flink

docker build -f ~/pika/Dockerfile -t master01:30500/bronzels/flink:0.1 ./
docker push master01:30500/bronzels/flink:0.1

~/scripts/myflink-cp-op.sh restart


#如果dag脚本的python第三方依赖项没有改变，可以跳过image building，只重启airflow
docker images|grep "<none>"|awk '{print $3}'|xargs docker rmi -f

docker images|grep airflow
docker images|grep airflow|awk '{print $3}'|xargs docker rmi -f
sudo ansible slavek8s -m shell -a"docker images|grep airflow|awk '{print \$3}'|xargs docker rmi -f"
docker images|grep airflow

docker build -t master01:30500/bronzels/airflow:1.10.10-python3.6 ./
docker push master01:30500/bronzels/airflow:1.10.10-python3.6


~/scripts/myairflow-cp-op.sh restart
