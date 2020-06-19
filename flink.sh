#ubuntu
cd ~
wget -c http://us.mirrors.quenda.co/apache/flink/flink-1.10.1/flink-1.10.1-bin-scala_2.11.tgz
tar xzvf flink-1.10.1-bin-scala_2.11.tgz
ln -s flink-1.10.1 flink
~flink/bin/kubernetes-session.sh \
  -Dkubernetes.cluster-id=myflink \
  -Dtaskmanager.memory.process.size=40960m \
  -Dkubernetes.taskmanager.cpu=4 \
  -Dtaskmanager.numberOfTaskSlots=8 \
  -Dresourcemanager.taskmanager-timeout=3600000