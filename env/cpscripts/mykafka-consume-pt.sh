ns=$1
echo "ns:${ns}"
topic=$2
echo "topic:${topic}"
offset=$3
echo "offset:${offset}"
pt=$4
echo "pt:${pt}"

kafka-console-consumer.sh --bootstrap-server pro-hbase02:9092,pro-hbase03:9092,pro-hbase04:9092 --topic $topic --$pos
kubectl -n default run test-kafka-producer-mqstr -ti --image=strimzi/kafka:0.18.0-kafka-2.5.0 --rm=true --restart=Never -- bin/kafka-console-consumer.sh --bootstrap-server mykafka.${ns}:9092 --topic ${topic} --offset ${offset} --partition ${pt}
