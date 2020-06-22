#!/bin/bash

cmd='set bd:k:fm:fl -fl'

kubectl -n default run test-redis -ti --image=redis --rm=true --restart=Never -- redis-cli -h myrdsvc ${cmd}

