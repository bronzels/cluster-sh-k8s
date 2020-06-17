
MYHOME=~/hdpallcp

cd ${MYHOME}/image

#apache-kylin-3.0.1-bin-hadoop3
cp ~/tmp/kylin.tar.gz ./
#   totally depends on ENV

file=Dockerfile.hdpallcp-kylin
cat << \EOF > ${file}
FROM master01:30500/bronzels/hdpallcp:0.1

# Add libs
WORKDIR ${MYHOME}
ADD kylin.tar.gz ./

ENV KYLIN_HOME=${MYHOME}/kylin

ENV PATH=${PATH}:$KYLIN_HOME/bin

# kylin ports
EXPOSE 7070

#CMD ${KYLIN_HOME}/bin/kylin.sh start && tail -f $KYLIN_HOME/logs/kylin.log
EOF

docker build -f Dockerfile.hdpallcp-kylin -t master01:30500/bronzels/hdpallcp-kylin:0.1 ./
docker push master01:30500/bronzels/hdpallcp-kylin:0.1

