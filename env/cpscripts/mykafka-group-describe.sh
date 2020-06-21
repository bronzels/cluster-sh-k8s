ns=$1
echo "ns:${ns}"
group=$2
echo "group:${group}"

kubectl -n default run test-kafka-producer-mqstr -ti --image=strimzi/kafka:0.18.0-kafka-2.5.0 --rm=true --restart=Never -- bin/kafka-consumer-groups.sh --bootstrap-server mykafka.${ns}:9092  --group ${group} --describe
