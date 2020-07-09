#hadoop测试
hadoop fs -ls /
hadoop fs -mkdir /test
hadoop fs -put ./other-env.sh /test/
ls -l other-env.sh
hadoop fs -ls /test/

#yarn测试
yarn node -list
#这个测试会产生2T文件，干挂2台slave，不要执行
#hadoop jar /opt/cloudera/parcels/CDH-6.3.2-1.cdh6.3.2.p0.1605554/lib/hadoop-mapreduce/hadoop-mapreduce-client-jobclient-3.0.0-cdh6.3.2-tests.jar TestDFSIO -write -nrFiles 30 -fileSize 100000
yarn application -list

#spark测试
/opt/cloudera/parcels/CDH/lib/spark/bin/run-example SparkPi 10 --master yarn
#Pi is roughly 3.141067141067141

#kudu测试
kudu master list 10.10.1.62:7051
kudu tserver list 10.10.1.62:7051
kudu table list 10.10.1.62:7051
