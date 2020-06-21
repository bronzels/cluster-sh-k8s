#!/bin/bash
prefix=$1
echo $prefix

echo "keys $prefix" | redis-cli -h 127.0.0.1 -p 6379 | xargs -L 1 redis-cli -c -h 127.0.0.1 -p 6379 del
