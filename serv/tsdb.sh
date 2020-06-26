git clone https://github.com/Gradiant/charts.git gradiant

MYHOME=~/gradiant/charts/opentsdb
cp -rf ${MYHOME} ${MYHOME}.bk

cd ${MYHOME}

tar xzvf ~/tmp/aws-hbase.tar.gz

file=templates/configmap-catalog.sh
rm -f ${file}
cat << \EOF > ${file}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "opentsdb.fullname" . }}-hbcm
  labels:
    app.kubernetes.io/name: {{ include "opentsdb.name" . }}
    {{- include "opentsdb.labels" . | nindent 4 }}
data:
  hbase-site.xml: |-
{{ tpl (.Files.Get "hbase/hbase-site.xml") . | indent 4 }}
EOF

rm -f requirements.yaml

file=templates/opentsdb-deployment.yaml
cp ${MYHOME}.bk/${file} ${file}
sed -i 's@          name: {{ .Release.Name }}-hbase@          name: {{ include "opentsdb.fullname" . }}-hbcm@g' ${file}

:<<EOF
# pass env vars to the opentsdb or init-container
env:
  # env.init -- values for init container when creating hbase tables
  init:
    # BLOOMFILTER: 'ROW'
    # META_TABLE: 'tsdb-meta'
    # TREE_TABLE: 'tsdb-tree'
    # TSDB_TABLE: 'tsdb'
    # UID_TABLE: tsdb-uid'
EOF

file=~/scripts/myopentsdb-cp-op.sh
rm -f ${file}
#cat ~/scripts/k8s_funcs.sh > ${file}
cat << \EOF > ${file}
#!/bin/bash

. ${HOME}/scripts/k8s_funcs.sh

op=$1
echo "op:${op}"
ns=$2
echo "ns:${ns}"
rev=$3
echo "rev:${rev}"

#set -e

cd ~/gradiant/charts/opentsdb

ZOOKEEPER_QUORUM=`cat hbase/zookeeper_quorum`
echo "ZOOKEEPER_QUORUM:$ZOOKEEPER_QUORUM"

if [ $op == "stop" -o $op == "restart" ]; then
  helm uninstall myopts -n ${ns}
  wait_pod_deleted "${ns}" "myopts-opentsdb" 4
fi

if [ $op == "start" -o $op == "restart" ]; then
helm install myopts -n ${ns} \
  --set hbase.enabled=false \
  --set antiAffinity="hard" \
  --set daemons=4 \
  --set nodePort.enabled=true \
  --set env.init.META_TABLE=tsdb-meta${rev} \
  --set env.init.TREE_TABLE=tsdb-tree${rev} \
  --set env.init.TSDB_TABLE=tsdb${rev} \
  --set env.init.UID_TABLE=tsdb-uid${rev} \
  --set conf."tsd\.storage\.hbase\.zk_quorum"="$ZOOKEEPER_QUORUM" \
  --set conf\."tsd\.network\.worker_threads"=8 \
  --set conf\."tsd\.core\.auto_create_metrics"=true \
  --set conf\."tsd\.storage\.hbase\.data_table"=tsdb${rev} \
  --set conf\."tsd\.storage\.hbase\.meta_table"=tsdb-meta${rev} \
  --set conf\."tsd\.storage\.hbase\.tree_table"=tsdb-tree${rev} \
  --set conf\."tsd\.storage\.hbase\.uid_table"=tsdb-uid${rev} \
  --set conf\."tsd\.http\.request\.enable_chunked"=true \
  --set conf\."tsd\.http\.request\.max_chunk"=65535 \
  --set conf\."tsd\.storage\.enable_compaction"=false \
  --set conf\."tsd\.storage\.fix_duplicates"=true \
  --set conf\."tsd\.core\.uid\.random_metrics"=true \
  --set conf\."tsd\.storage\.hbase\.prefetch_meta"=true \
  --set conf\."tsd\.storage\.salt\.width"=1 \
  --set conf\."tsd\.storage\.salt\.buckets"=20 \
  --set conf\."tsd\.core\.meta\.enable_tsuid_tracking"=true \
  --set conf\."tsd\.core\.meta\.enable_tsuid_incrementing"=true \
  --set conf\."tsd\.core\.meta\.enable_realtime_ts"=false \
  --set conf\."tsd\.storage\.enable_appends"=true \
  --set conf\."tsd\.core\.uid\.random_metrics"=true \
  ./
  wait_pod_running "${ns}" "myopts-opentsdb" 4
fi
EOF
chmod a+x ${file}

~/scripts/myopentsdb-cp-op.sh start serv 2_2_3_1_5
~/scripts/myopentsdb-cp-op.sh stop serv 2_2_3_1_5
~/scripts/myopentsdb-cp-op.sh restart serv 2_2_3_1_5

:<<EOF

kubectl get pod -n serv -o wide
kubectl get svc -n serv -o wide

kubectl get configmap -n serv
kubectl get configmap myopts-opentsdb-hbcm -n serv -o yaml

kubectl describe pod -n serv myopts-opentsdb-7f848db5b4-6qqsj
kubectl logs -n serv myopts-opentsdb-7f848db5b4-6qqsj
kubectl logs -n serv myopts-opentsdb-7f848db5b4-9x9jd
kubectl logs -n serv myopts-opentsdb-7f848db5b4-rssn8
kubectl logs -n serv myopts-opentsdb-7f848db5b4-xbwqm

kubectl exec -n serv myopts-opentsdb-7f848db5b4-xbwqm -- date

kubectl -n serv exec -ti myopts-opentsdb-7f848db5b4-rssn8 -- tsdb version

curl -ki -X POST -d '{"metric":"testdata", "timestamp":1524900185000, "value":9999.99, "tags":{"key":"value"}}' http://10.10.0.234:31042/api/put?sync
curl  -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://10.10.0.234:31042/api/query  -d '
    {
        "start": "1970/03/01 00:00:00",
        "end": "2029/12/16 00:00:00",
        "queries": [
            {
                "metric": "testdata",

                "aggregator": "none",
                "tags": {
                    "key": "value"
                }
            }
        ]
    }'

kubectl run curl-json -it --image=radial/busyboxplus:curl --restart=Never --rm -- curl -ki -X POST -d '{"metric":"testdata", "timestamp":1524900190000, "value":8888.88, "tags":{"key1":"value1"}}' http://myopts-opentsdb.serv:4242/api/put?sync
kubectl run curl-json -it --image=radial/busyboxplus:curl --restart=Never --rm -- curl  -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://myopts-opentsdb.serv:4242/api/query  -d '
    {
        "start": "1970/03/01 00:00:00",
        "end": "2029/12/16 00:00:00",
        "queries": [
            {
                "metric": "testdata",

                "aggregator": "none",
                "tags": {
                    "key1": "value1"
                }
            }
        ]
    }'

NOTES:
1. You can open access opentsdb CLI by running this command:
   kubectl -n serv exec -ti myopts-opentsdb-0 -- tsdb version

2. Get description of opentsdb service:
   kubectl -n serv describe service myopts-opentsdb
EOF