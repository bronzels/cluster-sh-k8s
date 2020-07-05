cd ~/charts/stable/
MYHOME=~/charts/stable/presto
cp -rf ${MYHOME} ${MYHOME}.bk

cd ${MYHOME}

unzip /tmp/resources.zip
cd resources
scp hk-prod-bigdata-slave-0-234:/etc/hadoop/conf/core-site.xml ./
scp hk-prod-bigdata-slave-0-234:/etc/hadoop/conf/hdfs-site.xml ./

cd ${MYHOME}
file=templates/configmap-catalog.sh
rm -f ${file}
cat << \EOF > ${file}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ template "presto.catalog" . }}
  labels:
    app: {{ template "presto.name" . }}
    chart: {{ template "presto.chart" . }}
    release: {{ .Release.Name }}
    heritage: {{ .Release.Service }}
    component: catalog
data:
  hive.properties: |-
{{ tpl (.Files.Get "resources/hive.properties") . | indent 4 }}
  core-site.xml: |-
{{ tpl (.Files.Get "resources/core-site.xml") . | indent 4 }}
  hdfs-site.xml: |-
{{ tpl (.Files.Get "resources/hdfs-site.xml") . | indent 4 }}
  kafka.properties: |-
{{ tpl (.Files.Get "resources/kafka.properties") . | indent 4 }}
  kudu.properties: |-
{{ tpl (.Files.Get "resources/kudu.properties") . | indent 4 }}
  kudu_without_emulation.properties: |-
{{ tpl (.Files.Get "catalog/kudu_without_emulation.properties") . | indent 4 }}
EOF

cd ${MYHOME}
:<<EOF
  config:
    path: /usr/lib/presto/etc
EOF
file=values.yaml
cp ${MYHOME}.bk/${file} ${file}
sed -i '/  config:/i\  catalog:\n    path: \/usr\/lib\/presto\/etc\/catalog' ${file}
#sed -i '/  config:/i\  plugin:\n    path: \/usr\/lib\/presto\/plugin\/comprplg' ${file}

:<<EOF
{{- define "presto.coordinator" -}}
{{ template "presto.fullname" . }}-coordinator
{{- end -}}
EOF
file=templates/_helpers.tpl
cp ${MYHOME}.bk/${file} ${file}
sed -i '/{{- define \"presto.coordinator\" -}}/i\{{- define \"presto.catalog\" -}}\n{{ template \"presto.fullname\" . }}-catalog\n{{- end -}}' ${file}

:<<EOF
sed -i '/      containers:/i\        - name: comprplg-volume\n          nfs:\n            server: 10.10.5.13\n            path: \/'  ${file}
sed -i '/          livenessProbe:/i\            - name: comprplg-volume\n              mountPath: {{ .Values.server.plugin.path }}' ${file}
EOF
file=templates/deployment-worker.yaml
cp ${MYHOME}.bk/${file} ${file}
:<<EOF
        - name: catalog-volume
          configMap:
            name: {{ template "presto.catalog" . }}
EOF
sed -i '/      containers:/i\        - name: catalog-volume\n          configMap:\n            name: {{ template \"presto.catalog\" . }}' ${file}
:<<EOF
            - mountPath: {{ .Values.server.catalog.path }}
              name: config-volume
EOF
sed -i '/          livenessProbe:/i\            - mountPath: {{ .Values.server.catalog.path }}\n              name: catalog-volume' ${file}
diff ${MYHOME}.bk/${file} ${file}

:<<EOF
sed -i '/      containers:/i\        - name: comprplg-volume\n          nfs:\n            server: 10.10.5.13\n            path: \/'  ${file}
sed -i '/          ports:/i\            - name: comprplg-volume\n              mountPath: {{ .Values.server.plugin.path }}' ${file}
EOF
file=templates/deployment-coordinator.yaml
cp ${MYHOME}.bk/${file} ${file}
sed -i '/      containers:/i\        - name: catalog-volume\n          configMap:\n            name: {{ template \"presto.catalog\" . }}' ${file}
:<<EOF
            - mountPath: {{ .Values.server.config.path }}
              name: config-volume
EOF
sed -i '/          ports:/i\            - mountPath: {{ .Values.server.catalog.path }}\n              name: catalog-volume' ${file}

find ${MYHOME}/templates -name "*.yaml"  | xargs grep "apps/v1beta2"
find ${MYHOME}/templates -name "*.yaml" | xargs sed -i 's@apps/v1beta2@apps/v1@g'
find ${MYHOME}/templates -name "*.yaml"  | xargs grep "apps/v1beta2"

cp /tmp/fmkcplugin-0.0.1-SNAPSHOT.jar ./comprplg/

file=Dockerfile
cat << \EOF > ${file}
FROM prestosql/presto
MAINTAINER bronzels <bronzels@hotmail.com>

ADD comprplg /usr/lib/presto/plugin/comprplg
EOF

docker images|grep "<none>"|awk '{print $3}'|xargs docker rmi -f

docker images|grep presto
docker images|grep presto|awk '{print $3}'|xargs docker rmi -f
sudo ansible slavek8s -m shell -a"docker images|grep presto|awk '{print \$3}'|xargs docker rmi -f"
docker images|grep presto

docker build -t master01:30500/prestosql/presto:0.1 ./
docker push master01:30500/prestosql/presto:0.1

rm -f ./comprplg/fmkcplugin-0.0.1-SNAPSHOT.jar

file=templates/service.yaml
sed -i '/      name: http-coord/i\      nodePort: 30080' ${file}

file=~/scripts/myprestoserver-cp-op.sh
rm -f ${file}
cat << \EOF > ${file}
#!/bin/bash

cd ~/charts/stable/presto

#set -e

#  --set server.config.query.maxMemory=30GB \
#  --set server.config.query.maxMemoryPerNode=8GB \
#  --set server.jvm.maxHeapSize=36G
if [ $1 == "stop" -o $1 == "restart" ]; then
  helm uninstall mypres -n dw
fi

if [ $1 == "start" -o $1 == "restart" ]; then
  helm install mypres -n dw \
    --set server.workers=4 \
    --set service.type=NodePort \
    --set server.config.query.maxMemory=60GB \
    --set server.config.query.maxMemoryPerNode=16GB \
    --set server.jvm.maxHeapSize=72G \
    --set image.repository="master01:30500/prestosql/presto" \
    --set image.tag="0.1" \
    ./
fi
EOF
chmod a+x ${file}

docker run -d -p 2049:2049 --name mynfs-presto --privileged -v ${MYHOME}/comprplg:/nfsshare -e SHARED_DIRECTORY=/nfsshare itsthenetwork/nfs-server-alpine:latest
sudo mount -t nfs -o port=2049 10.10.5.13:/ test
#docker run -d -p 2149:2049 --name mynfs-presto --privileged -v ${MYHOME}/comprplg:/nfsshare -e SHARED_DIRECTORY=/nfsshare itsthenetwork/nfs-server-alpine:latest
#sudo mount -t nfs -o port=2149 10.10.5.13:/ test
sudo umount test

~/scripts/myprestoserver-cp-op.sh start
~/scripts/myprestoserver-cp-op.sh stop
~/scripts/myprestoserver-cp-op.sh restart

:<<EOF

kubectl get pod -n dw
kubectl describe pod `kubectl get pod -n dw | grep coordinator | awk '{print $1}'` -n dw

kubectl exec -n dw -t mypres-presto-worker-7664dd8dd7-ch2j8  -- ls -l /usr/lib/presto/plugin/comprplg
kubectl logs -n dw mypres-presto-worker-7664dd8dd7-ch2j8

--server http://beta-hbase01:8070 --catalog hive --schema default

EOF

:<<EOF
NOTES:
Get the application URL by running these commands:
  export NODE_PORT=$(kubectl get --namespace dw -o jsonpath="{.spec.ports[0].nodePort}" services mypres-presto)
  export NODE_IP=$(kubectl get nodes --namespace dw -o jsonpath="{.items[0].status.addresses[0].address}")
  echo http://$NODE_IP:$NODE_PORT
EOF
