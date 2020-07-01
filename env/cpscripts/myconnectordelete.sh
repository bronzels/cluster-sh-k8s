#!/bin/bash
set -x

ns=$1
echo "ns:${ns}"
name=$2
echo "name:${name}"

kubectl run curl-json -it --image=radial/busyboxplus:curl --restart=Never --rm -- curl -i -X DELETE -H "Accept:application/json" -H "Content-Type:application/json" myconnsvc.${ns}-${name}:8083/myconn
