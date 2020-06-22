#!/bin/bash

if [ -n "$1" ] ;then
db="/$1"
fi
echo "db:$db"
mongo ???:3717/$db -u "root" -p "rootRoot!@#" --authenticationDatabase "admin"
