#如果是
#   项目定制开发
#   spark-loaded2dw
#把k8sdeploy.sh打包生成k8sdeploy.tar.gz上传到slave01，解压到home目录
#!/usr/bin/env bash

:<<EOF
#example:
deploy_slave01_batch.sh
deploy_slave01_batch.sh -l all
deploy_slave01_batch.sh -l few
EOF

lib="no"
while getopts ":l:" opt; do
  case $opt in
    l)
      lib="$OPTARG"
      ;;
    \?)
      echo "Invalid option: -$OPTARG"
      ;;
  esac
done

set -x

#如果依赖库没有更改，只是主程序修改，没必要执行以下步骤：
#if there are libraries, either com or 3rd, tared into spark_jars.tar.gz
if [ "$lib" != "no" ]; then
  if [ "$lib" == "all" ]; then
    ansible allcdh -m shell -a"rm -rf ~/spark_shared_jars"
    ansible allcdh -m copy -a"src=/tmp/spark_shared_jars_3rd.zip dest=~/"
    ansible allcdh -m shell -a"cd ~;unzip spark_shared_jars_3rd.zip;rm -f ~/spark_shared_jars_3rd.zip"
  fi
  ansible allcdh -m copy -a"src=~/k8sdeploy_dir/spark_jars.tgz dest=~/spark_shared_jars/"
  ansible allcdh -m shell -a"cd ~/spark_shared_jars;tar xzvf spark_jars.tgz;cd spark_jars;cp *.jar ../;cd ..;rm -rf spark_jars.tgz spark_jars/"
fi

