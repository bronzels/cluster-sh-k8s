#!/bin/bash
set -x

scripts_type=$1
echo "scripts_type:${scripts_type}"

:<<EOF
deploy-scripts.sh cpscripts #master01
deploy-scripts.sh scripts #slave01
deploy-scripts.sh hbscripts #hbase master
EOF

cd ${HOME}
tar xzvf /tmp/k8sdeploy-scripts.tar.gz
#rm -f ${HOME}/scripts/*
#这句一定不能加，因为*-cp-op.sh的cp操作脚本都是在执行安装脚本是cat生成的，而不是保存在env目录中的，这句执行这些脚本就都木诶了
#如果不慎删除，要去安装脚本找到生成这些脚本的部分，重新执行生成这些脚本部分
#k8s_funcs.sh
#myairflow-cp-op.sh  myconnector-cp-op.sh  myopentsdb-cp-op.sh
#mycodis-cp-op.sh    myflink-cp-op.sh      myprestoserver-cp-op.sh
cp ${HOME}/k8sdeploy-scripts/${scripts_type}/* ${HOME}/scripts
chmod a+x ${HOME}/scripts/*.sh
