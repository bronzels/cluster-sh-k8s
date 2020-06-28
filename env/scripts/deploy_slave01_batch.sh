#如果是
#   项目定制开发
#   spark-loaded2dw
#把k8sdeploy.sh打包生成k8sdeploy.tar.gz上传到slave01，解压到home目录

#如果依赖库没有更改，只是主程序修改，没必要执行以下步骤：
#if there are libraries, either com or 3rd, tared into spark_jars.tar.gz
ansible allcdh -m copy -a"src=~/k8sdeploy_dir/spark_shared_jars.tar.gz dest=~/"
ansible allcdh -m shell -a"cd ~/spark_shared_jars/;rm -f *;tar xzvf ~/spark_shared_jars.tar.gz;rm -f ~/spark_shared_jars.tar.gz"
