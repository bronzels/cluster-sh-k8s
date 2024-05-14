#!/bin/bash

ns=$1
echo "ns:${ns}"
pod=$2
echo "pod:${pod}"
cmd=$3
echo "cmd:${cmd}"

kubectl -n ${ns} exec -it ${pod}-0 -- bin/zkCli.sh ${cmd}
