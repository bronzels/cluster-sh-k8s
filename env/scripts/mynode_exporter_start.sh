#!/bin/bash

nohup /var/lib/hadoop-hdfs/node_exporter/node_exporter-0.18.1.linux-amd64/node_exporter --web.listen-address=":9101" > /var/lib/hadoop-hdfs/node_exporter/node_exporter-0.18.1.linux-amd64/node_exporter.log 2>&1 &
