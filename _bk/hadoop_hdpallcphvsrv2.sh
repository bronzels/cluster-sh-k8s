
MYHOME=~/hdpallcp

cd ${MYHOME}/image

file=Dockerfile.hdpallcphvsrv2
cat << \EOF > ${file}
FROM master01:30500/bronzels/hdpallcp:0.1

CMD nohup ${HIVE_HOME}/bin/hive --service hiveserver2 >> ${HIVE_HOME}/logs/hiveserver2.log 2>&1 &

# hive-server2 ports
EXPOSE 9084
EOF

docker build -f Dockerfile.hdpallcphvsrv2 -t master01:30500/bronzels/hdpallcphvsrv2:0.1 ./
docker push master01:30500/bronzels/hdpallcphvsrv2:0.1

