
MYHOME=~/hdpallcp

cd ${MYHOME}/image

#apache-kylin-3.0.1-bin-hadoop3
cp /tmp/kylin.tar.gz ./
#   totally depends on ENV

file=Dockerfile.hdpallcpkylin
cat << \EOF > ${file}
FROM master01:30500/bronzels/hdpallcp:0.1

# Add libs
ADD kylin.tar.gz /usr/local

ENV KYLIN_HOME=/usr/local/kylin

ENV PATH=${PATH}:$KYLIN_HOME/bin

# kylin ports
EXPOSE 7070

CMD nohup ${KYLIN_HOME}/bin/kylin.sh start
EOF

docker build -f Dockerfile.hdpallcpkylin -t master01:30500/bronzels/hdpallcpkylin:0.1 ./
docker push master01:30500/bronzels/hdpallcpkylin:0.1

