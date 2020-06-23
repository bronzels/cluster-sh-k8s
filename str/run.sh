#!/bin/bash

FLINK_JOB_MANAGER_SH=$FLINK_HOME/bin/jobmanager.sh
FLINK_TASK_MANAGER_SH=$FLINK_HOME/bin/taskmanager.sh

case "$1" in
"jobmanager")
$FLINK_JOB_MANAGER_SH start-foreground
;;

"taskmanager")
$FLINK_TASK_MANAGER_SH start-foreground
;;

*)
echo "COMMAND ERROR"
;;
esac