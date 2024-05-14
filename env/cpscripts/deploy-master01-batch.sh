#!/usr/bin/env bash
#如果是
#   项目定制开发
#   spark-loaded2dw
#把k8sdeploy.sh打包生成k8sdeploy.tar.gz上传到master01，解压到home目录

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

cp -rfv ~/k8sdeploy_dir/batch_jar ~/nfsmnt/

#如果依赖库没有更改，只是主程序修改，没必要执行以下步骤：
#if there are libraries, either com or 3rd, tared into spark_jars.tar.gz
if [ "$lib" != "no" ]; then
  if [ "$lib" == "all" ]; then
    rm -rf ~/nfsmnt/spark_shared_jars
    mkdir ~/nfsmnt/spark_shared_jars
  fi
  cd ~/nfsmnt/spark_shared_jars
  tar xzvf ~/k8sdeploy_dir/spark_shared_jars.tar.gz
fi

