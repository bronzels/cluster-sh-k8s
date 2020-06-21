echo "Removing logs of name nodes [pro-hbase01 pro-hbase02]"
rm -f /app/hadoop/hadoop/logs/hadoop-hadoop-namenode-pro-hbase01.out
rm -f /app/hadoop/hadoop/logs/hadoop-hadoop-namenode-pro-hbase02.out
echo "Removing logs of data nodes [pro-hbase02 pro-hbase03 pro-hbase04]"
rm -f /app/hadoop/hadoop/logs/hadoop-hadoop-datanode-pro-hbase02.out
rm -f /app/hadoop/hadoop/logs/hadoop-hadoop-datanode-pro-hbase04.out
rm -f /app/hadoop/hadoop/logs/hadoop-hadoop-datanode-pro-hbase03.out
echo "Removing logs of journal nodes [pro-hbase02 pro-hbase03 pro-hbase04]"
rm -f /app/hadoop/hadoop/logs/hadoop-hadoop-journalnode-pro-hbase02.out
rm -f /app/hadoop/hadoop/logs/hadoop-hadoop-journalnode-pro-hbase04.out
rm -f /app/hadoop/hadoop/logs/hadoop-hadoop-journalnode-pro-hbase03.out
echo "Removing logs of ZK Failover Controllers on NN hosts [pro-hbase01 pro-hbase02]"
rm -f /app/hadoop/hadoop/logs/hadoop-hadoop-zkfc-pro-hbase01.out
rm -f /app/hadoop/hadoop/logs/hadoop-hadoop-zkfc-pro-hbase02.out

