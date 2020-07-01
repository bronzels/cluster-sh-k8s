#!/bin/bash

exec hbase shell <<EOF
disable_all 'KYLIN.*'
drop_all 'KYLIN.*'
EOF
