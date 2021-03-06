
cd ~

git clone https://github.com/chenseanxy/helm-hadoop-3.git
rm -rf helm-hadoop-3.bk
cp -r helm-hadoop-3 helm-hadoop-3.bk

HDPHOME=~/helm-hadoop-3
HADOOPREV=3.2.1

cd $HDPHOME

cd image

docker images|grep hadoop
docker images|grep hadoop|awk '{print $3}'|xargs docker rmi -f
sudo ansible slavek8s -m shell -a"docker images|grep hadoop|awk '{print \$3}'|xargs docker rmi -f"
docker images|grep hadoop

file=Dockerfile
cp ~/helm-hadoop-3.bk/image/${file} ${file}.template
sed -i '/ENV HADOOP_PREFIX/a\    HADOOP_HOME=/usr/local/hadoop \\' ${file}.template
sed -i '/    YARN_CONF_DIR/a\    YARN_HOME=/usr/local/hadoop \\' ${file}.template

cp ${file}.template ${file}
#sed -i 's@FROM java:8-jre@FROM anapsix\/alpine-java@g' ${file}
#替换为alpine以后，datanode/nodemanager不能启动

file=Makefile
cp ~/helm-hadoop-3.bk/image/$file $file
sed -i "s@HADOOP_30_VERSION = 3.2.1@HADOOP_30_VERSION = ${HADOOPREV}@g" ${file}

make
#helm install错误kubernetes Error: create: failed to create: Request entity too large: limit is 3145728
rm hadoop-${HADOOPREV}.tar.gz
docker tag hadoop:${HADOOPREV}-nolib master01:30500/chenseanxy/hadoop:${HADOOPREV}-nolib
docker push master01:30500/chenseanxy/hadoop:${HADOOPREV}-nolib

cp ~/sources.list.ubuntu.16.04 sources.list
file=Dockerfile
cp ${file}.template ${file}
sed -i 's@FROM java:8-jre@FROM paulosalgado\/oracle-java8-ubuntu-16@g' ${file}

#cp ~/source.list.ubuntu.16.04 source.list
#COPY ./source.list /etc/apt
cat << \EOF >> ${file}

COPY sources.list /etc/apt
RUN apt-get update
RUN apt-get install -y openssh-server
RUN sed -i 's@PermitRootLogin prohibit-password@PermitRootLogin yes@g' /etc/ssh/sshd_config
RUN sed -i 's@#PasswordAuthentication yes@PasswordAuthentication yes@g' /etc/ssh/sshd_config
RUN usermod --password $(echo root | openssl passwd -1 -stdin) root

EXPOSE 22
EOF

cp Makefile Makefile-ubu16ssh
sed -i 's@$(DOCKER) build -t hadoop@$(DOCKER) build -t hadoop-ubu16ssh@g' Makefile-ubu16ssh
make -f Makefile-ubu16ssh

docker tag hadoop-ubu16ssh:${HADOOPREV}-nolib master01:30500/chenseanxy/hadoop-ubu16ssh:${HADOOPREV}-nolib
docker push master01:30500/chenseanxy/hadoop-ubu16ssh:${HADOOPREV}-nolib

rm hadoop-${HADOOPREV}.tar.gz

cd $HDPHOME
file=values.yaml
cp ~/helm-hadoop-3.bk/$file $file
sed -i 's@repository: chenseanxy/hadoop@repository: master01:30500/chenseanxy/hadoop@g' ${file}
sed -i "s@tag: 3.2.1-nolib@tag: ${HADOOPREV}-nolib@g" ${file}
sed -i "s@hadoopVersion: 3.2.1@hadoopVersion: ${HADOOPREV}@g" ${file}
sed -i 's@pullPolicy: IfNotPresent@pullPolicy: Always@g' ${file}

find $HDPHOME -name "*.yaml" | xargs grep "apps/v1beta1"
find $HDPHOME -name "*.yaml" | xargs sed -i 's@apps/v1beta1@apps/v1@g'

sed -i '/  serviceName:/i\  selector:\n      matchLabels:\n        app: {{ include "hadoop.name" . }}' templates/yarn-nm-statefulset.yaml
sed -i '/  serviceName:/i\  selector:\n      matchLabels:\n        app: {{ include "hadoop.name" . }}' templates/hdfs-dn-statefulset.yaml
sed -i '/  serviceName:/i\  selector:\n      matchLabels:\n        app: {{ include "hadoop.name" . }}' templates/yarn-rm-statefulset.yaml
sed -i '/  serviceName:/i\  selector:\n      matchLabels:\n        app: {{ include "hadoop.name" . }}' templates/hdfs-nn-statefulset.yaml

file=templates/hadoop-configmap.yaml
cp ../helm-hadoop-3.bk/$file $file
#sed -i 's@@@g' $file

rm -f templates/hdfs-dn-pvc.yaml
file=templates/hdfs-dn-statefulset.yaml
cp ../helm-hadoop-3.bk/$file $file
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
