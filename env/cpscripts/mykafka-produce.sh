ns=$1
echo "ns:${ns}"
topic=$2
echo "topic:${topic}"

kubectl -n default run test-kafka-producer-mqstr -ti --image=strimzi/kafka:0.18.0-kafka-2.5.0 --rm=true --restart=Never -- bin/kafka-console-producer.sh  --broker-list mykafka.${ns}:9092 --topic ${topic}
