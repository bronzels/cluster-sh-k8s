git clone https://github.com/Gradiant/charts.git

MYHOME=~/gradiant/charts/opentsdb
cp ${MYHOME} ${MYHOME}.bk

cd ${MYHOME}

cp ~/tmp/aws-hbase.tar.gz ./
tar xzvf aws-hbase.tar.gz

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
sed -i 's@          name: {{ .Release.Name }}-hbase@          name: {{ .Release.Name }}-hbcm@g' ${file}

file=~/scripts/myopentsdb-restart.sh
rm -f ${file}
cat ~/scripts/k8s_funcs.sh > ${file}
cat << \EOF >> ${file}
#!/bin/bash
ns=$1
echo "ns:${ns}"
rev=$2
echo "rev:${rev}"

set -e

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

helm uninstall myopts -n ${ns}
helm install myopts -n ${ns} \
  --set hbase.enabled=false \
  --set antiAffinity="hard" \
  --set daemons=1 \
  --set nodePort.enabled=true \
  --set env.META_TABLE=tsdb-meta${rev} \
  --set env.TREE_TABLE=tsdb-tree${rev} \
  --set env.TSDB_TABLE=tsdb${rev} \
  --set env.UID_TABLE=tsdb-uid${rev} \
  --conf zookeeper.tsd.storage.hbase.zk_quorum="" \
  ./
# gradiant/opentsdb
EOF
chmod a+x ${file}

${file} serv 2_2_3_1_4
