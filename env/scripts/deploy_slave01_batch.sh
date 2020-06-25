#如果是
#   项目定制开发
#   spark-loaded2dw
#的批处理部分有修改，#把k8sdeploy.sh打包生成k8sdeploy.tar.gz上传到跳板机
#root
cd ~

tar xzvf /tmp/k8sdeploy.tar.gz

#if there are libraries, either com or 3rd, tared into spark_jars.tar.gz
~/scripts/deploy_spark_jars.sh

