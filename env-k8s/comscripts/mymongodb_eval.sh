#!/bin/bash
cmd="docker run --rm mongo:4.0 mongo --forceTableScan ???:???/ -u "admin" -p "rootRoot!@#" --authenticationDatabase "admin""
if [ ! -n "$1" ] ;then 
$cmd
else
$cmd --eval "$1"
fi
