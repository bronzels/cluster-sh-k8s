git clone https://github.com/wiwdata/presto-chart.git

MYHOME=~/presto-chart
cp -rf ${MYHOME} ${MYHOME}.bk

cd ${MYHOME}

cd ${MYHOME}/presto

file=values.yaml
cp ${MYHOME}.bk/presto/${file} ${file}
sed -i 's@catalog: {}@#catalog: {}@g'  ${file}
sed -i 's@coordinatorConfigs: {}@#coordinatorConfigs: {}@g'  ${file}
sed -i 's@workerConfigs: {}@#workerConfigs: {}@g'  ${file}
cat << \EOF >> ${file}

catalog:
  hive.properties: |
    connector.name=hive-hadoop2
    hive.metastore.uri=thrift://1110.1110.1.62:9083
    hive.allow-drop-table=true
    hive.config.resources=/presto/etc/hivconf/core-site.xml,/presto/etc/hivconf/hdfs-site.xml

  kafka-dw.properties: |
    connector.name=kafka
    kafka.nodes=mykafka.mqdw:9092
    kafka.table-names=test
    kafka.hide-internal-columns=false

  kafka-str.properties: |
    connector.name=kafka
    kafka.nodes=mykafka.mqstr:9092
    kafka.table-names=test
    kafka.hide-internal-columns=false

  kudu.properties: |
    connector.name=kudu
    kudu.client.master-addresses=1110.1110.1.62:7051
    kudu.schema-emulation.enabled=true
    kudu.schema-emulation.prefix=v1::

  kudu_without_emulation.properties: |
    connector.name=kudu
    kudu.client.master-addresses=1110.1110.1.62:7051
    kudu.schema-emulation.enabled=false

coordinatorConfigs:
  config.properties: |
    node-scheduler.include-coordinator=false
    query.max-memory=30GB
    query.max-memory-per-node=8GB
    discovery-server.enabled=true

  jvm.config: |
    -server
    -Xmx36G
    -Xms10G
    -XX:+UseG1GC
    -XX:G1HeapRegionSize=32M
    -XX:+UseGCOverheadLimit
    -XX:+ExplicitGCInvokesConcurrent
    -XX:+HeapDumpOnOutOfMemoryError
    -XX:+ExitOnOutOfMemoryError

workerConfigs:
  config.properties: |
    query.max-memory=30GB

  jvm.config: |
    -server
    -Xmx36G
    -Xms10G
    -XX:+UseG1GC
    -XX:G1HeapRegionSize=32M
    -XX:+UseGCOverheadLimit
    -XX:+ExplicitGCInvokesConcurrent
    -XX:+HeapDumpOnOutOfMemoryError
    -XX:+ExitOnOutOfMemoryError

EOF

mkdir hivconf

scp 1110.1110.1.62:/etc/hadoop/conf/core-site.xml hivconf/
scp 1110.1110.1.62:/etc/hadoop/conf/hdfs-site.xml hivconf/

file=templates/configmap-hivconf.sh
rm -f ${file}
cat << \EOF > ${file}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ template "presto.hivconf" . }}
  labels:
    app: {{ template "presto.name" . }}
    chart: {{ template "presto.chart" . }}
    release: {{ .Release.Name }}
    heritage: {{ .Release.Service }}
    component: catalog
data:
  core-site.xml: |-
{{ tpl (.Files.Get "hivconf/core-site.xml") . | indent 4 }}
  hdfs-site.xml: |-
{{ tpl (.Files.Get "hivconf/hdfs-site.xml") . | indent 4 }}
EOF


:<<EOF
{{- define "presto.coordinator" -}}
{{ template "presto.fullname" . }}-coordinator
{{- end -}}
EOF
file=templates/_helpers.tpl
cp ${MYHOME}.bk/presto/${file} ${file}
sed -i '/{{- define \"presto.coordinator\" -}}/i\{{- define \"presto.hivconf\" -}}\n{{ template \"presto.fullname\" . }}-hivconf\n{{- end -}}' ${file}

file=templates/deployment-coordinator.yaml
cp ${MYHOME}.bk/presto/${file} ${file}
:<<EOF
        - name: config-volume
          configMap:
            name: {{ template "presto.coordinator" . }}
EOF
sed -i '/      containers:/i\        - name: hivconf-volume\n          configMap:\n            name: {{ template \"presto.hivconf\" . }}' ${file}
:<<EOF
            - mountPath: /presto/templates/custom_conf
              name: config-volume
EOF
sed -i '/          resources:/i\            - mountPath: \/presto\/etc\/hivconf\n              name: hivconf-volume' ${file}
sed -i 's@---@#---@g' ${file}
diff ${MYHOME}.bk/presto/${file} ${file}

file=templates/deployment-worker.yaml
cp ${MYHOME}.bk/presto/${file} ${file}
:<<EOF
        - name: configs-volume
          configMap:
            name: {{ template "presto.worker" . }}
EOF
sed -i '/      containers:/i\        - name: hivconf-volume\n          configMap:\n            name: {{ template \"presto.hivconf\" . }}' ${file}
:<<EOF
            - mountPath: {{ .Values.server.catalog.path }}
              name: config-volume
EOF
sed -i '/          resources:/i\            - mountPath: \/presto\/etc\/hivconf\n              name: hivconf-volume' ${file}
sed -i 's@---@#---@g' ${file}
diff ${MYHOME}.bk/presto/${file} ${file}

cat << \EOF > host_aliases
      hostAliases:
      - ip: "1110.1110.1.62"
        hostnames:
        - "hk-prod-bigdata-slave-1-62"
      - ip: "1110.1110.11.47"
        hostnames:
        - "hk-prod-bigdata-slave-11-47"
      - ip: "1110.1110.13.106"
        hostnames:
        - "hk-prod-bigdata-slave-13-106"
      - ip: "1110.1110.3.169"
        hostnames:
        - "hk-prod-bigdata-slave-3-169"
EOF
#cdh的web安装部分，如果hosts用ip加入就不需要域名索引了
cat host_aliases >> templates/deployment-coordinator.yaml
cat host_aliases >> templates/deployment-worker.yaml

find ${MYHOME}/presto/templates -name "*.yaml"  | xargs grep "apps/v1beta2"
find ${MYHOME}/presto/templates -name "*.yaml" | xargs sed -i 's@apps/v1beta2@apps/v1@g'
find ${MYHOME}/presto/templates -name "*.yaml"  | xargs grep "apps/v1beta2"

cd ${MYHOME}/image

cp -rf ~/k8sdeploy_dir/comprplg ./

file=Dockerfile
cp ${MYHOME}.bk/presto/${file} ${file}
cat << \EOF >> ${file}

ADD comprplg /presto/plugin/comprplg
EOF
diff ${MYHOME}.bk/image/${file} ${file}

docker images|grep "<none>"|awk '{print $3}'|xargs docker rmi -f

docker images|grep presto
docker images|grep presto|awk '{print $3}'|xargs docker rmi -f
sudo ansible slavek8s -m shell -a"docker images|grep presto|awk '{print \$3}'|xargs docker rmi -f"
docker images|grep presto

python3 manager.py build --version 0.218

docker tag wiwdata/presto:0.218 master01:30500/wiwdata/presto:0.1
docker push master01:30500/wiwdata/presto:0.1

rm -rf ${MYHOME}/image/comprplg

cd ${MYHOME}/presto

file=templates/service.yaml
sed -i '/      protocol: TCP/a\      nodePort: 30080' ${file}

file=~/scripts/myprestoserver-cp-op.sh
rm -f ${file}
cat << \EOF > ${file}
#!/bin/bash

. ${HOME}/scripts/k8s_funcs.sh

cd ~/presto-chart/presto

#set -e

#  --set server.config.query.maxMemory=30GB \
#  --set server.config.query.maxMemoryPerNode=8GB \
#  --set server.jvm.maxHeapSize=36G
if [ $1 == "stop" -o $1 == "restart" ]; then
  uinstall_helm_if_found "dw" "mypres"
  wait_pod_deleted "dw" "mypres-presto-coordinator" 600
  wait_pod_deleted "dw" "mypres-presto-worker" 600
fi

if [ $1 == "start" -o $1 == "restart" ]; then
  helm install mypres -n dw \
    --set presto.workers=4 \
    --set service.type=NodePort \
    --set image.repository="master01:30500/wiwdata/presto" \
    --set image.tag="0.1" \
    ./
  wait_pod_running "dw" "mypres-presto-coordinator" 1 600
  wait_pod_running "dw" "mypres-presto-worker" 4 600

  wait_pod_log_line "dw" "mypres-presto-coordinator" "======== SERVER STARTED ========" 900
fi
EOF
chmod a+x ${file}

~/scripts/myprestoserver-cp-op.sh start
~/scripts/myprestoserver-cp-op.sh stop
~/scripts/myprestoserver-cp-op.sh restart

kubectl -n default run test-presto -ti --image=master01:30500/wiwdata/presto:0.1 --rm=true --restart=Never -- presto --server http://1110.1110.1.62:30080 --catalog kudu_without_emulation
  #把项目目定制开发的com-schema.sql的数仓版本改为v1
  #执行com-schema.sql，插入需要模拟的schema

:<<EOF

kubectl get pod -n dw
kubectl describe pod `kubectl get pod -n dw | grep coordinator | awk '{print $1}'` -n dw

kubectl exec -n dw -t `kubectl get pod -n dw | grep coordinator | awk '{print $1}'`  -- ls -l /presto/plugin/comprplg
kubectl logs -n dw mypres-presto-coordinator-5b4d7bf85d-d629x

kubectl -n default run test-presto -ti --image=master01:30500/wiwdata/presto:0.1 --rm=true --restart=Never -- presto --server http://1110.1110.1.62:30080 --catalog hive --schema default
  SHOW TABLES;
  SELECT COUNT(1) FROM kylin_sales;

EOF

NOTES:
Get the application URL by running these commands:
  export NODE_PORT=$(kubectl get --namespace dw -o jsonpath="{.spec.ports[0].nodePort}" services mypres-presto)
  export NODE_IP=$(kubectl get nodes --namespace dw -o jsonpath="{.items[0].status.addresses[0].address}")
  echo http://$NODE_IP:$NODE_PORT
EOF
