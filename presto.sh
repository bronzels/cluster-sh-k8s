
MYHOME=~/charts/stable/presto
cp ${MYHOME} ${MYHOME}.bk

cd ${MYHOME}

cd ${MYHOME}/resources
cp ~/tmp/presto-catalog.zip ./
unzip xzvf presto-catalog.zip
scp hk-prod-bigdata-slave-0-234:/etc/hadoop/conf/core-site.xml ./
scp hk-prod-bigdata-slave-0-234:/etc/hadoop/conf/hdfs-site.xml ./

:<<EOF
  config:
    path: /usr/lib/presto/etc
EOF
file=templates/configmap-catalog.sh
sed -i '/  config:/i\  catalog:\n    path: \/usr\/lib\/presto\/etc\/catalog' ${file}

:<<EOF
{{- define "presto.coordinator" -}}
{{ template "presto.fullname" . }}-coordinator
{{- end -}}
EOF
file=templates/_helpers.tpl
sed -i '/{{- define \"presto.coordinator\" -}}/i\{{- define \"presto.coordinator\" -}}\n{{ template \"presto.fullname\" . }}-catalog\n{{- end -}}' ${file}

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
{{ tpl (.Files.Get "catalog/hive.properties") . | indent 4 }}
  core-site.xml: |-
{{ tpl (.Files.Get "catalog/core-site.xml") . | indent 4 }}
  hdfs-site.xml: |-
{{ tpl (.Files.Get "catalog/hdfs-site.xml") . | indent 4 }}
  kafka.properties: |-
{{ tpl (.Files.Get "catalog/kafka.properties") . | indent 4 }}
  kudu.properties: |-
{{ tpl (.Files.Get "catalog/kudu.properties") . | indent 4 }}
  kudu_without_emulation.properties: |-
{{ tpl (.Files.Get "catalog/kudu_without_emulation.properties") . | indent 4 }}
EOF


:<<EOF
        - name: config-volume
          configMap:
            name: {{ template "presto.worker" . }}
EOF
file=templates/deployment-worker.yaml
sed -i '/      containers:/i\        - name: catalog-volume\n          configMap:\n            name: {{ template \"presto.catalog\" . }}' ${file}
:<<EOF
            - mountPath: {{ .Values.server.config.path }}
              name: config-volume
EOF
sed -i '/          livenessProbe:/i\            - mountPath: {{ .Values.server.catalog.path }}\n              name: catalog-volume' ${file}

file=templates/deployment-coordinator.yaml
sed -i '/      containers:/i\        - name: catalog-volume\n          configMap:\n            name: {{ template \"presto.catalog\" . }}' ${file}
:<<EOF
            - mountPath: {{ .Values.server.config.path }}
              name: config-volume
EOF
sed -i '/          ports:/i\            - mountPath: {{ .Values.server.catalog.path }}\n              name: catalog-volume' ${file}

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
    --set service.type=NodePort
    --set server.config.query.maxMemory=60GB \
    --set server.config.query.maxMemoryPerNode=16GB \
    --set server.jvm.maxHeapSize=24G \
    ./
fi
EOF
chmod a+x ${file}

${file}

