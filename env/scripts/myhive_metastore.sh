#!/bin/bash

nohup ~/hive/bin/hive --service metastore >> ~/hive/logs/metastore.log 2>&1 &
echo $! > hive-metastore.pid
