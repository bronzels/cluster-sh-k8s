#!/bin/bash

cmd='get bd:k:fm:fl'

redis-cli -c -h 127.0.0.1 -p 6379 ${cmd}
