#!/bin/bash
set -x

version_prefix=$1
echo "version_prefix:${version_prefix}"

:<<EOF
deploy.sh 2_2_4_0_0
EOF

cd ~
rm -rf k8sdeploy_dir
cp /tmp/${version_prefix}-k8sdeploy.tar.gz ~/released/
tar xzvf ~/released/${version_prefix}-k8sdeploy.tar.gz
