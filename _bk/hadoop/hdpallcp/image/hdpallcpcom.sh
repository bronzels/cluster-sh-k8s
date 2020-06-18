
MYHOME=~/hdpallcp
cd ${MYHOME}/image

cp /tmp/scripts.tar.gz ./
cp /tmp/cpscripts.tar.gz ./
cp /tmp/comscripts.tar.gz ./
cp /tmp/comcpscripts.tar.gz ./
cp /tmp/spark_shared_jars.tar.gz ./
cp /tmp/spark_jars.tar.gz ./
cp /tmp/com_spark_jars.tar.gz ./

file=Dockerfile.hdpallcp-com
cat << \EOF > ${file}
FROM master01:30500/bronzels/hdpallcp:0.1

# Add libs
ENV MYSCRIPTSHOME ${MYHOME}/scripts
RUN mkdir {MYSCRIPTSHOME}

ADD scripts.tar.gz {MYSCRIPTSHOME}
ADD cpscripts.tar.gz {MYSCRIPTSHOME}
ADD comscripts.tar.gz {MYSCRIPTSHOME}
ADD spark_shared_jars.tar.gz {MYSCRIPTSHOME}
ADD com_spark_lib_jars.tar.gz {MYSCRIPTSHOME}
ADD com_spark_entry_jars.tar.gz {MYSCRIPTSHOME}
chmod a+x {MYSCRIPTSHOME}/*.sh

ENV PATH=${PATH}:{MYSCRIPTSHOME}
ENTRYPOINT ["entrypoint.sh"]
EOF

docker build -f Dockerfile.hdpallcp-com -t master01:30500/bronzels/hdpallcp-com:0.1 ./
docker push master01:30500/bronzels/hdpallcp-com:0.1

rm -f *.tar.gz
cd ${MYHOME}
