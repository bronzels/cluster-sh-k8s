#!/bin/bash

cmd='get bd:k:fm:fl'

kubectl -n default run test-redis -ti --image=redis --rm=true --restart=Never -- redis-cli -h myrdsvc ${cmd}
