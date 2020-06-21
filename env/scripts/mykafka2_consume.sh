topic=$1
echo "topic:$topic"

kafka-console-consumer.sh --bootstrap-server pro-hbase06:9492,pro-hbase07:9492,pro-hbase08:9492 --topic $topic
