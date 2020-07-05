#!/usr/bin/env bash

:<<EOF
#example:
./k8sdeploy-scripts.sh /mnt/u
./k8sdeploy-scripts.sh /i
EOF

currdir=$PWD

prj_home=$1
echo "prj_home:${prj_home}"

rm -rf k8sdeploy-scripts
mkdir k8sdeploy-scripts

mkdir k8sdeploy-scripts/cpscripts
cp -v ${prj_home}/cluster-sh-k8s/env/deploy.sh k8sdeploy-scripts/cpscripts/
cp -v ${prj_home}/cluster-sh-k8s/env/deploy-scripts.sh k8sdeploy-scripts/cpscripts/
cp -v ${prj_home}/comdeploy/env-k8s/comcpscripts/* k8sdeploy-scripts/cpscripts/
cp -v ${prj_home}/cluster-sh-k8s/env/cpscripts/* k8sdeploy-scripts/cpscripts/

mkdir k8sdeploy-scripts/hbscripts
cp -v ${prj_home}/cluster-sh-k8s/env/deploy-scripts.sh k8sdeploy-scripts/hbscripts/
cp -v ${prj_home}/comdeploy/env-k8s/comhbscripts/* k8sdeploy-scripts/hbscripts/
cp -v ${prj_home}/cluster-sh-k8s/env/hbscripts/* k8sdeploy-scripts/hbscripts/

mkdir k8sdeploy-scripts/scripts
cp -v ${prj_home}/cluster-sh-k8s/env/deploy.sh k8sdeploy-scripts/scripts/
cp -v ${prj_home}/cluster-sh-k8s/env/deploy-scripts.sh k8sdeploy-scripts/scripts/
cp -v ${prj_home}/comdeploy/env-k8s/comscripts/* k8sdeploy-scripts/scripts/
cp -v ${prj_home}/cluster-sh-k8s/env/scripts/* k8sdeploy-scripts/scripts/

tar czvf k8sdeploy-scripts.tar.gz k8sdeploy-scripts/

cd ${currdir}/

