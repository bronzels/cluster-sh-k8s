
cd ~
git clone https://github.com/chenseanxy/helm-hbase-chart.git
cp -r helm-hbase-chart helm-hbase-chart.bk
cd ~/helm-hbase-chart
sed -i 's@FROM chenseanxy\/hadoop:3.2.1-nolib@FROM master01:30500\/chenseanxy\/hadoop:3.2.1-nolib@g' image/Dockerfile

cd image
make
sed -i 's@FROM chenseanxy\/hadoop:3.2.1-nolib@FROM master01:30500\/chenseanxy\/hadoop:3.2.1-nolib@g' Dockerfile
docker tag hbase:2.1.7-hadoop3.1.2 master01:30500/chenseanxy/hbase:2.1.7-hadoop3.1.2
docker push master01:30500/chenseanxy/hbase:2.1.7-hadoop3.1.2

cd ~/helm-hbase-chart

file=values.yaml
cp ~/helm-hbase-chart.bk/$file $file
sed -i '/hbaseImage: /a\pullPolicy: Always' ${file}
sed -i 's@hbaseImage: chenseanxy\/hbase:1.4.10-hadoop3.1.2@hbaseImage: master01:30500\/chenseanxy\/hbase:2.1.7-hadoop3.1.2@g' ${file}

file=templates/hbase-configmap.yaml
cp ~/helm-hbase-chart.bk/$file $file
sed -i 's@<value>{{ template \"hbase.name\" . }}-hbase-master:16010<\/value>@<value>{{ .Release.Name }}-hbase-master:16010<\/value>@g' ${file}
sed -i 's@<value>\/hbase<\/value>@<value>\/hbase-unsecure<\/value>@g' ${file}
#sed -i '/    <\/configuration>/i\      <property>\n        <name>hbase.zookeeper.property.clientPort<\/name>\n        <value>2281<\/value>\n      <\/property>' ${file}

find ~/helm-hbase-chart -name "*.yaml" | xargs grep 'apps/v1beta1'
find ~/helm-hbase-chart -name "*.yaml" | xargs sed -i 's@apps/v1beta1@apps/v1@g'

function fix_statefulset_affinity(){
  myhbasefile=$1
  sed -i '/  serviceName:/i\  selector:\n      matchLabels:\n        app: {{ template "hbase.name" . }}' $myhbasefile
  sed -i '/      affinity:/a\        podAffinity:' $myhbasefile
  sed -i 's@      requiredDuringSchedulingIgnoredDuringExecution:@          requiredDuringSchedulingIgnoredDuringExecution:@g' $myhbasefile
  sed -i 's@          - topologyKey: \"kubernetes.io\/hostname\"@              - topologyKey: \"kubernetes.io\/hostname\"@g' $myhbasefile
  sed -i 's@            labelSelector:@                labelSelector:@g' $myhbasefile
  sed -i 's@              matchLabels:@                  matchLabels:@g' $myhbasefile
  sed -i 's@                app:  {{ \.Values\.hbase\.hdfs\.name }}@                    app:  {{ .Release.Namespace }}@g' $myhbasefile
  sed -i 's@                release: {{ \.Values\.hbase\.hdfs\.release | quote }}@                    release: {{ \.Values\.hbase\.hdfs\.release | quote }}@g' $myhbasefile
}

:<<EOF
    spec:
      affinity:
      requiredDuringSchedulingIgnoredDuringExecution:
          - topologyKey: "kubernetes.io/hostname"
            labelSelector:
              matchLabels:
                app:  {{ template "hbase.name" . }}
                release: {{ .Values.hbase.hdfs.release | quote }}
                component: hdfs-nn
    spec:
      affinity:
        podAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
              - topologyKey: "kubernetes.io/hostname"
                labelSelector:
                  matchLabels:
                    app:  {{ .Release.Namespace }}
                    release: {{ .Values.hbase.hdfs.release | quote }}
                    component: hdfs-nn
EOF

file=templates/hbase-master-statefulset.yaml
cp ~/helm-hbase-chart.bk/$file $file
fix_statefulset_affinity "$file"
sed -i 's@                component: hdfs-nn@                    component: hdfs-nn@g' $file
#sed -i s's@@@g' $file
:<<EOF
    spec:
      affinity:
      requiredDuringSchedulingIgnoredDuringExecution:
          - topologyKey: "kubernetes.io/hostname"
            labelSelector:
              matchLabels:
                app:  {{ template "hbase.name" . }}
                release: {{ .Values.hbase.hdfs.release | quote }}
                component: hdfs-nn
    spec:
      affinity:
        podAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
              - topologyKey: "kubernetes.io/hostname"
                labelSelector:
                  matchLabels:
                    app:  {{ .Release.Namespace }}
                    release: {{ .Values.hbase.hdfs.release | quote }}
                    component: hdfs-dn
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
              - topologyKey: "kubernetes.io/hostname"
                labelSelector:
                  matchLabels:
                    app:  {{ .Release.Namespace }}
                    release: {{ .Release.Name }}
                    component: hbase-rs
EOF


file=templates/hbase-rs-statefulset.yaml
cp ~/helm-hbase-chart.bk/$file $file
fix_statefulset_affinity "$file"
sed -i 's@                component: hdfs-nn@                    component: hdfs-dn@g' $file
sed -i '/                    component: hdfs-dn/a\        podAntiAffinity:\n          requiredDuringSchedulingIgnoredDuringExecution:\n              - topologyKey:\ "kubernetes.io\/hostname\"\n                labelSelector:\n                  matchLabels:\n                    app:  {{ .Release.Namespace | quote }}\n                    release: {{ .Release.Name | quote }}\n                    component: hbase-rs' $file
sed -i 's@{{ toYaml .Values.hdfs.nameNode.resources | indent 10 }}@{{ toYaml .Values.hdfs.dataNode.resources | indent 10 }}@g' ${file}

cat << \EOF > templates/hbase-master-web-svc.yaml
# A headless service to create DNS records
apiVersion: v1
kind: Service
metadata:
  name: {{ template "hbase.fullname" . }}-master-web
  labels:
    app: {{ template "hbase.name" . }}
    chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
    release: {{ .Release.Name }}
    heritage: {{ .Release.Service }}
    component: hbase-master
spec:
  type: NodePort
  ports:
  - port: 16010
    name: masterinfoweb
    nodePort: 31010
  selector:
    app: {{ template "hbase.name" . }}
    release: {{ .Release.Name }}
    component: hbase-master
EOF

#  --set hbase.zookeeper.quorum="myzk-zookeeper-0.myzk-zookeeper-headless\,myzk-zookeeper-1.myzk-zookeeper-headless\,myzk-zookeeper-2.myzk-zookeeper-headles" \
helm install myhb -n hadoop -f values.yaml \
  --set hbase.hdfs.name="myhdp-hadoop" \
  --set hbase.hdfs.release="myhdp" \
  --set hdfs.dataNode.replicas=4 \
  --set hdfs.dataNode.pdbMinAvailable=4 \
  --set hbase.zookeeper.quorum="myzk-zookeeper:2181" \
  --set hdfs.dataNode.resources.requests.memory="4096Mi" \
  --set hdfs.dataNode.resources.requests.cpu="2000m" \
  --set hdfs.dataNode.resources.limits.memory="8196Mi" \
  --set hdfs.dataNode.resources.limits.cpu="4000m" \
  ./
:<<EOF
helm uninstall myhb -n hadoop
kubectl exec myzk-zookeeper-0 -n hadoop -- bin/zkCli.sh deleteall /hbase
kubectl exec -n hadoop -it myhdp-hadoop-hdfs-nn-0 -- /usr/local/hadoop/bin/hdfs dfs -rm -r -f /hbase

kubectl describe pod hbase-rs-0 -n hadoop
kubectl describe pod myhb-hbase-master-0 -n hadoop

kubectl exec -it myhb-hbase-master-0 -n hadoop -- bash
bin/hbase-daemons.sh start thrift2

kubectl get pod -n hadoop -o wide
kubectl get pvc -n hadoop -o wide
kubectl get svc -n hadoop -o wide
EOF

:<<EOF
kubectl exec -it myhb-hbase-master-0 -n hadoop bash
  bin/hbase shell
    list

kubectl -n hadoop run test-python3 -ti --image=python:3.7 --rm=true --restart=Never -- bash
  pip install happybase
  python3

import happybase
conn = happybase.Connection(host='myhb-hbase-master', port=9090)

conn.create_table(
    'my_table',
    {
        'cf1': dict(max_versions=10),
        'cf2': dict(max_versions=1, block_cache_enabled=False),
        'cf3': dict()
    }
)
tables = conn.tables()
for t in tables:
    print(t)


http://master01:31010
EOF

:<<EOF
kubectl -n hadoop run test-ubuntu -ti --image=ubuntu --rm=true --restart=Never -- bash
EOF
cat << \EOF > /etc/apt/source.list
deb http://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ focal-proposed main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-proposed main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse
EOF
:<<EOF
apt-get update
apt-get install -y telnet
telnet myhb-hbase-master 9090
EOF
