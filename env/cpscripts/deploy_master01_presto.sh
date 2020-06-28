#如果是项目定制开发的presto plugin部分有修改
#把k8sdeploy.sh打包生成k8sdeploy.tar.gz上传到master01，解压到home目录

MYHOME=~/presto-chart
cd ${MYHOME}/image

cp -rf ~/k8sdeploy_dir/comprplg ./

docker images|grep "<none>"|awk '{print $3}'|xargs docker rmi -f

docker images|grep presto
docker images|grep presto|awk '{print $3}'|xargs docker rmi -f
sudo ansible slavek8s -m shell -a"docker images|grep presto|awk '{print \$3}'|xargs docker rmi -f"
docker images|grep presto

python3 manager.py build --version 0.218

docker tag wiwdata/presto:0.218 master01:30500/wiwdata/presto:0.1
docker push master01:30500/wiwdata/presto:0.1

rm -rf ${MYHOME}/image/comprplg

~/scripts/myprestoserver-cp-op.sh restart

