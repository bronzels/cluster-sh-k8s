
cd ~

git clone https://github.com/chenseanxy/helm-hadoop-3.git
cp -r helm-hadoop-3 helm-hadoop-3.bk

cp -r charts/stable/hadoop charts/stable/hadoop.bk

HDPHOME=~/helm-hadoop-3

cd $HDPHOME

cd image
make
docker tag hadoop:3.2.1-nolib master01:30500/chenseanxy/hadoop:3.2.1-nolib

cd $HDPHOME
sed -i 's@repository: chenseanxy/hadoop@repository: master01:30500/chenseanxy/hadoop@g' values.yaml
sed -i 's@pullPolicy: IfNotPresent@pullPolicy: Always@g' values.yaml

find $HDPHOME -name "*.yaml" | xargs grep "apps/v1beta1"
find $HDPHOME -name "*.yaml" | xargs sed -i 's@apps/v1beta1@apps/v1@g'

sed -i '/  serviceName:/i\  selector:\n      matchLabels:\n        app: {{ include "hadoop.name" . }}' templates/yarn-nm-statefulset.yaml
sed -i '/  serviceName:/i\  selector:\n      matchLabels:\n        app: {{ include "hadoop.name" . }}' templates/hdfs-dn-statefulset.yaml
sed -i '/  serviceName:/i\  selector:\n      matchLabels:\n        app: {{ include "hadoop.name" . }}' templates/yarn-rm-statefulset.yaml
sed -i '/  serviceName:/i\  selector:\n      matchLabels:\n        app: {{ include "hadoop.name" . }}' templates/hdfs-nn-statefulset.yaml

file=templates/hadoop-configmap.yaml
#cp ../helm-hadoop-3.bk/$file $file
sed -i 's@<value>{{ include \"hadoop.fullname\" . }}-yarn-rm<\/value>@<value>{{ include \"hadoop.fullname\" . }}-yarn-rm-0<\/value>@g' $file
#sed -i 's@curl -sf http:\/\/{{ include \"hadoop.fullname\" . }}-yarn-rm@curl -sf http:\/\/{{ include \"hadoop.fullname\" . }}-yarn-rm-0@g' $file
#sed -i 's@{{ include \"hadoop.fullname\" \. }}-yarn-rm-0\.{{ include \"hadoop.fullname\" \. }}-yarn-rm@{{ include \"hadoop.fullname\" \. }}-yarn-rm-0@g' $file
#sed -i 's@@@g' $file

rm -f templates/hdfs-dn-statefulset.yaml
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
