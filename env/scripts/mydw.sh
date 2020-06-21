#!/bin/bash
cat=$1
echo "cat:${cat}"
op=$2
echo "op:${op}"
kuduport=$3
echo "kuduport:${kuduport}"

if [ $cat == "dw" ]; then
if [ $op == "start" ]; then
if [ $kuduport == "7052" ]; then
~/scripts/mykuduserver.sh start
~/scripts/myprestoserver.sh start
else
~/scripts/mykudu2server.sh start
~/scripts/myprestoserver2.sh start
fi
else
if [ $kuduport == "7052" ]; then
~/scripts/myprestoserver.sh stop
~/scripts/mykuduserver.sh stop
else
~/scripts/myprestoserver2.sh stop
~/scripts/mykudu2server.sh stop
fi
fi
elif [ $cat == "kudu" ]; then
if [ $op == "start" ]; then
if [ $kuduport == "7052" ]; then
~/scripts/mykuduserver.sh start
else
~/scripts/mykudu2server.sh start
fi
else
if [ $kuduport == "7052" ]; then
~/scripts/mykuduserver.sh stop
else
~/scripts/mykudu2server.sh stop
fi
fi
else
if [ $op == "start" ]; then
if [ $kuduport == "7052" ]; then
~/scripts/myprestoserver.sh start
else
~/scripts/myprestoserver2.sh start
fi
else
if [ $kuduport == "7052" ]; then
~/scripts/myprestoserver.sh stop
else
~/scripts/myprestoserver2.sh stop
fi
fi
fi

