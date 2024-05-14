#!/bin/bash
#如果是项目定制开发的dag部分有修改
#把k8sdeploy.sh打包生成k8sdeploy.tar.gz上传到master01，解压到home目录
set -x

:<<EOF
#example:
deploy_master01_dags.sh
deploy_master01_dags.sh -rb
EOF

rb="no"
for var in $*
do
  echo "var:${var}"
  if [ "$var" == "-rb" ]; then
    rb="yes"
  fi
done

set -x

rm -rf ${HOME}/nfsmnt/dags
cp -rvf ~/k8sdeploy_dir/dags ${HOME}/nfsmnt/

#如果dag脚本的python第三方依赖项没有改变，可以跳过image building，只重启airflow

if [ "$rb" == "yes" ]; then
  cd ~/myairflow

  docker images|grep "<none>"|awk '{print $3}'|xargs docker rmi -f

  docker images|grep airflow
  docker images|grep airflow|awk '{print $3}'|xargs docker rmi -f
  sudo ansible slavek8s -m shell -a"docker images|grep airflow|awk '{print \$3}'|xargs docker rmi -f"
  docker images|grep airflow

  docker build -t master01:30500/bronzels/airflow:1.1110.1110-python3.6 ./
  docker push master01:30500/bronzels/airflow:1.1110.1110-python3.6
fi

~/scripts/myairflow-cp-op.sh restart
