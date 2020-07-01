#!/bin/bash
set -x

ns=$1
echo "ns:${ns}"
name=$2
echo "name:${name}"

kubectl run curl-json -it --image=radial/busyboxplus:curl --restart=Never --rm -- curl myconnsvc.${ns}-${name}:8083/myconn/status
