#!/bin/bash
nohup ~/hive/bin/hive --service hiveserver2 >> ~/hive/logs/hiveserver2.log 2>&1 &
echo $! > hiveserver2.pid
