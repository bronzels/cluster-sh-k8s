#!/bin/bash
~/presto-server/bin/presto-cli --server http://pro-hbase01:8070 --catalog kafka --schema default
