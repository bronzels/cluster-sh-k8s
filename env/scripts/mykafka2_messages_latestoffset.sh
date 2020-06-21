echo `date`
topic=$1
#echo "topic:$topic"
kafka-run-class.sh kafka.tools.GetOffsetShell --broker-list pro-hbase06:9492,pro-hbase07:9492,pro-hbase08:9492 --topic $topic --time -1 --offsets 1
