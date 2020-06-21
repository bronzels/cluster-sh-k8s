echo `date`
group=$1
echo "group:$group"
kafka-consumer-groups.sh --bootstrap-server pro-hbase06:9492,pro-hbase07:9492,pro-hbase08:9492 --group $group --describe
