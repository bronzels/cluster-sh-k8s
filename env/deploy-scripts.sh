#!/bin/bash
set -x

scripts_type=$1
echo "scripts_type:${scripts_type}"

cd ${HOME}
tar xzvf /tmp/k8sdeploy-scripts.tar.gz
cp ${HOME}/k8sdeploy-scripts/${scripts_type}/* ${HOME}/scripts
chmod a+x ${HOME}/scripts/*.sh
