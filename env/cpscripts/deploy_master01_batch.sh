#如果是
#   项目定制开发
#   spark-loaded2dw
#把k8sdeploy.sh打包生成k8sdeploy.tar.gz上传到master01，解压到home目录

#if there are libraries, either com or 3rd, tared into spark_jars.tar.gz
cp ~/k8sdeploy_dir/spark_shared_jars ~/spark

docker images|grep "<none>"|awk '{print $3}'|xargs docker rmi -f

docker images|grep spark
docker images|grep spark|awk '{print $3}'|xargs docker rmi -f
ansible slavek8s -i /etc/ansible/hosts-ubuntu -m shell -a"docker images|grep spark|awk '{print \$3}'|xargs docker rmi -f"
docker images|grep spark

./bin/docker-image-tool.sh build
./bin/docker-image-tool.sh push


