MYHOME=~/hdpallcp

cd ${MYHOME}/image

cp /tmp/scripts.tar.gz ./
#   no dep, pure client
cp /tmp/cpscripts.tar.gz ./
#   no dep, pure client
cp /tmp/comscripts.tar.gz ./
#   no dep, pure client
cp /tmp/comcpscripts.tar.gz ./
#   no dep, pure client

file=Dockerfile.hdpallcpcom
cat << \EOF > ${file}
FROM master01:30500/bronzels/hdpallcp:0.1

# Add libs
{MYSCRIPTSHOME}/scripts
RUN mkdir {MYSCRIPTSHOME}
ADD scripts.tar.gz {MYSCRIPTSHOME}
ADD cpscripts.tar.gz {MYSCRIPTSHOME}
ADD comscripts.tar.gz {MYSCRIPTSHOME}
ADD comcpscripts.tar.gz {MYSCRIPTSHOME}

ENV PATH=${PATH}:{MYSCRIPTSHOME}

EOF

docker build -f Dockerfile.hdpallcpcom -t master01:30500/bronzels/hdpallcpcom:0.1 ./
docker push master01:30500/bronzels/hdpallcpcom:0.1
