cp -r charts/stable/hadoop charts/stable/hadoop.bk

HDPHOME=~/charts/stable/hadoop

docker pull danisla/hadoop:2.9.0
docker tag danisla/hadoop:2.9.0 master01:30500/chenseanxy/hadoop:3.2.1-nolib
docker push master01:30500/chenseanxy/hadoop:3.2.1-nolib

cd $HDPHOME
sed -i 's@repository: danisla/hadoop@repository: master01:30500/chenseanxy/hadoop@g' values.yaml
sed -i 's@tag: 2.9.0@tag: 3.2.1-nolib@g' values.yaml
sed -i 's@pullPolicy: IfNotPresent@pullPolicy: Always@g' values.yaml
