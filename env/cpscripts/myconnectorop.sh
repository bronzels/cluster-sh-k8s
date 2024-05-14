#!/bin/bash
set -x

ns=$1
echo "ns:${ns}"
name=$2
echo "name:${name}"

if [ ${op} == "start" ]; then
  op=resume
else
  op=pause
fi

kubectl run curl-json -it --image=radial/busyboxplus:curl --restart=Never --rm -- curl -s -X PUT myconnsvc.${ns}-${name}:8083/myconn/${op}
