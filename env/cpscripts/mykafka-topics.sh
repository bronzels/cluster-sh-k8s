ns=$1
echo "ns:${ns}"

kubectl -n default run test-kafka-producer-mqstr -ti --image=strimzi/kafka:0.18.0-kafka-2.5.0 --rm=true --restart=Never -- bin/kafka-topics.sh --zookeeper ???.${ns}:2181/???
