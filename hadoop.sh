helm install myzk -n hadoop incubator/zookeeper
:<<EOF
NOTES:
Thank you for installing ZooKeeper on your Kubernetes cluster. More information
about ZooKeeper can be found at https://zookeeper.apache.org/doc/current/

Your connection string should look like:
  myzk-zookeeper-0.myzk-zookeeper-headless:2181,myzk-zookeeper-1.myzk-zookeeper-headless:2181,...

You can also use the client service myzk-zookeeper:2181 to connect to an available ZooKeeper server.
EOF
#helm uninstall myzk -n hadoop
#myzk-zookeeper-0.myzk-zookeeper-headless:2181,myzk-zookeeper-1.myzk-zookeeper-headless:2181,myzk-zookeeper-2.myzk-zookeeper-headless:2181
#myzk-zookeeper:2181

cd ~
git clone https://github.com/chenseanxy/helm-hadoop-3.git
cp -r helm-hadoop-3 helm-hadoop-3.bk

cd ~/helm-hadoop-3
find . -name "*.yaml" | xargs sed -i 's@apps/v1beta1@apps/v1@g'

sed -i '/  serviceName:/i\  selector:\n      matchLabels:\n        app: {{ include "hadoop.name" . }}' templates/yarn-nm-statefulset.yaml
sed -i '/  serviceName:/i\  selector:\n      matchLabels:\n        app: {{ include "hadoop.name" . }}' templates/hdfs-dn-statefulset.yaml
sed -i '/  serviceName:/i\  selector:\n      matchLabels:\n        app: {{ include "hadoop.name" . }}' templates/yarn-rm-statefulset.yaml
sed -i '/  serviceName:/i\  selector:\n      matchLabels:\n        app: {{ include "hadoop.name" . }}' templates/hdfs-nn-statefulset.yaml

rm -f templates/hdfs-dn-pvc.yaml
cat << \EOF > templates/hdfs-dn-statefulset.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: {{ include "hadoop.fullname" . }}-hdfs-dn
  annotations:
    checksum/config: {{ include (print $.Template.BasePath "/hadoop-configmap.yaml") . | sha256sum }}
  labels:
    app: {{ include "hadoop.name" . }}
    chart: {{ include "hadoop.chart" . }}
    release: {{ .Release.Name }}
    component: hdfs-dn
spec:
  selector:
      matchLabels:
        app: {{ include "hadoop.name" . }}
  serviceName: {{ include "hadoop.fullname" . }}-hdfs-dn
  replicas: {{ .Values.hdfs.dataNode.replicas }}
  template:
    metadata:
      labels:
        app: {{ include "hadoop.name" . }}
        release: {{ .Release.Name }}
        component: hdfs-dn
    spec:
      affinity:
        podAntiAffinity:
        {{- if eq .Values.antiAffinity "hard" }}
          requiredDuringSchedulingIgnoredDuringExecution:
          - topologyKey: "kubernetes.io/hostname"
            labelSelector:
              matchLabels:
                app:  {{ include "hadoop.name" . }}
                release: {{ .Release.Name | quote }}
                component: hdfs-dn
        {{- else if eq .Values.antiAffinity "soft" }}
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 5
            podAffinityTerm:
              topologyKey: "kubernetes.io/hostname"
              labelSelector:
                matchLabels:
                  app:  {{ include "hadoop.name" . }}
                  release: {{ .Release.Name | quote }}
                  component: hdfs-dn
        {{- end }}
      terminationGracePeriodSeconds: 0
      containers:
      - name: hdfs-dn
        image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
        imagePullPolicy: {{ .Values.image.pullPolicy | quote }}
        command:
           - "/bin/bash"
           - "/tmp/hadoop-config/bootstrap.sh"
           - "-d"
        resources:
{{ toYaml .Values.hdfs.dataNode.resources | indent 10 }}
        readinessProbe:
          httpGet:
            path: /
            port: 9864
          initialDelaySeconds: 5
          timeoutSeconds: 2
        livenessProbe:
          httpGet:
            path: /
            port: 9864
          initialDelaySeconds: 10
          timeoutSeconds: 2
        volumeMounts:
        - name: hadoop-config
          mountPath: /tmp/hadoop-config
        - name: dfs
          mountPath: /root/hdfs/datanode
      volumes:
      - name: hadoop-config
        configMap:
          name: {{ include "hadoop.fullname" . }}
      {{- if not .Values.persistence.dataNode.enabled }}
      - name: dfs
        emptyDir: {}
      {{- end }}
  {{- if .Values.persistence.dataNode.enabled }}
  volumeClaimTemplates:
    - metadata:
        name: dfs
      spec:
        accessModes:
          - {{ .Values.persistence.dataNode.accessMode | quote }}
        resources:
          requests:
            storage: {{ .Values.persistence.dataNode.size | quote }}
      {{- if .Values.persistence.dataNode.storageClass }}
        {{- if (eq "-" .Values.persistence.dataNode.storageClass) }}
        storageClassName: ""
        {{- else }}
        storageClassName: "{{ .Values.persistence.dataNode.storageClass }}"
        {{- end }}
      {{- end }}
  {{- end }}
EOF

rm -f templates/yarn-rm-svc.yaml
cat << \EOF > templates/yarn-rm-svc.yaml
# A headless service to create DNS records
apiVersion: v1
kind: Service
metadata:
  name: {{ include "hadoop.fullname" . }}-yarn-rm
  labels:
    app: {{ include "hadoop.name" . }}
    chart: {{ include "hadoop.chart" . }}
    release: {{ .Release.Name }}
    component: yarn-rm
spec:
  type: NodePort
  ports:
  - port: 8088
    name: web
    nodePort: 31088
  selector:
    app: {{ include "hadoop.name" . }}
    release: {{ .Release.Name }}
    component: yarn-rm
EOF

cat << \EOF > templates/hdfs-nn-web-svc.yaml
# A headless service to create DNS records
apiVersion: v1
kind: Service
metadata:
  name: {{ include "hadoop.fullname" . }}-hdfs-nn-web
  labels:
    app: {{ include "hadoop.name" . }}
    chart: {{ include "hadoop.chart" . }}
    release: {{ .Release.Name }}
    component: hdfs-nn
spec:
  type: NodePort
  ports:
  - port: 9870
    name: web
    nodePort: 30870
  selector:
    app: {{ include "hadoop.name" . }}
    release: {{ .Release.Name }}
    component: hdfs-nn
EOF

#chmod a+x tools/calc_resources.sh
#helm install myhadoop $(tools/calc_resources.sh 50) -n hadoop -f values.yaml \
helm install myhdp -n hadoop -f values.yaml \
  --set hdfs.dataNode.replicas=4 \
  --set yarn.nodeManager.replicas=4 \
  --set persistence.nameNode.enabled=true \
  --set persistence.nameNode.storageClass=rook-ceph-block \
  --set persistence.dataNode.enabled=true \
  --set persistence.dataNode.storageClass=rook-ceph-block \
  --set persistence.nameNode.size=128Gi \
  --set persistence.dataNode.size=1024Gi \
  --set hdfs.dataNode.resources.requests.memory="4096Mi" \
  --set hdfs.dataNode.resources.requests.cpu="2000m" \
  --set hdfs.dataNode.resources.limits.memory="8196Mi" \
  --set hdfs.dataNode.resources.limits.cpu="4000m" \
  --set yarn.nodeManager.resources.requests.memory="16384Mi" \
  --set yarn.nodeManager.resources.requests.cpu="4000m" \
  --set yarn.nodeManager.resources.limits.memory="65536Mi" \
  --set yarn.nodeManager.resources.limits.cpu="14000m" \
  ./
#helm uninstall myhdp -n hadoop
#kubectl get pvc -n hadoop | awk '{print $1}' | grep dfs-myhdp | xargs kubectl delete pvc -n hadoop

#kubectl get pod -n hadoop
#kubectl get pvc -n hadoop
#kubectl get svc -n hadoop

:<<EOF
NOTES:
1. You can check the status of HDFS by running this command:
   kubectl exec -n hadoop -it myhdp-hadoop-hdfs-nn-0 -- /usr/local/hadoop/bin/hdfs dfsadmin -report
   kubectl exec -n hadoop -it myhdp-hadoop-hdfs-nn-0 -- /usr/local/hadoop/bin/hdfs dfs -ls /

2. You can list the yarn nodes by running this command:
   kubectl exec -n hadoop -it myhdp-hadoop-yarn-rm-0 -- /usr/local/hadoop/bin/yarn node -list

3. Create a port-forward to the yarn resource manager UI:
   #kubectl port-forward -n hadoop myhdp-hadoop-yarn-rm-0 8088:8088

   Then open the ui in your browser:

   #open http://localhost:8088
   yarn: http://master01:31088/cluster
   hdfs: http://master01:30870/dfshealth.html#tab-overview

4. You can run included hadoop tests like this:
   kubectl exec -n hadoop -it myhdp-hadoop-yarn-nm-0 -- /usr/local/hadoop/bin/hadoop jar /usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-client-jobclient-3.2.1-tests.jar TestDFSIO -write -nrFiles 5 -fileSize 128MB -resFile /tmp/TestDFSIOwrite.txt

5. You can list the mapreduce jobs like this:
   kubectl exec -n hadoop -it myhdp-hadoop-yarn-rm-0 -- /usr/local/hadoop/bin/mapred job -list

6. This chart can also be used with the zeppelin chart
    helm install --namespace hadoop --set hadoop.useConfigMap=true,hadoop.configMapName=myhdp-hadoop stable/zeppelin

7. You can scale the number of yarn nodes like this:
   helm upgrade myhdp --set yarn.nodeManager.replicas=4 stable/hadoop

   Make sure to update the values.yaml if you want to make this permanent.
EOF

git clone https://github.com/chenseanxy/helm-hbase-chart.git
cd helm-hbase-chart