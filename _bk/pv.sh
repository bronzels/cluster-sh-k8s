ansible slave -i /etc/ansible/hosts-ubuntu -m shell -a"rm -rf ~/mypv;mkdir ~/mypv"
ansible slave -i /etc/ansible/hosts-ubuntu -m shell -a"chmod 777 ~/mypv"
ansible slave -i /etc/ansible/hosts-ubuntu -m shell -a"ls -l ~/mypv"

file=~/local-storage-class.yaml
rm -f $file
cat >> $file << EOF
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: local-storage
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
EOF
kubectl apply -f ~/local-storage-class.yaml
#kubectl delete -f ~/local-storage-class.yaml

file=~/test-local-storage-pv.yaml
rm -f $file
cat >> $file << EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: localpath
spec:
  capacity:
    storage: 5Gi
  volumeMode: Filesystem
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Delete
  storageClassName: local-storage
  local:
    path: /home/ubuntu/mypv
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - hk-prod-bigdata-slave-14-52
          - hk-prod-bigdata-slave-3-239
          - hk-prod-bigdata-slave-4-34
          - hk-prod-bigdata-slave-5-114
EOF
kubectl apply -f ~/test-local-storage-pv.yaml

file=~/test-local-storage-pvc.yaml
rm -f $file
cat >> $file << EOF
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: local-storage-claim
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 512Mi
  storageClassName: local-storage
EOF
kubectl apply -f ~/test-local-storage-pvc.yaml

file=~/test-local-storage-pod.yaml
rm -f $file
cat >> $file << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: tomcat-deploy
spec:
  replicas: 1
  selector:
    matchLabels:
      appname: myapp
  template:
    metadata:
      name: myapp
      labels:
        appname: myapp
    spec:
      containers:
      - name: myapp
        image: tomcat:8.5.38-jre8
        ports:
        - name: http
          containerPort: 8080
          protocol: TCP
        volumeMounts:
          - name: tomcatedata
            mountPath : "/data"
      volumes:
        - name: tomcatedata
          persistentVolumeClaim:
            claimName: local-storage-claim
EOF
kubectl apply -f ~/test-local-storage-pod.yaml

kubectl get pv -n default
kubectl get pvc -n default
kubectl get pod -n default
kubectl delete -f ~/test-local-storage-pod.yaml
kubectl delete -f ~/test-local-storage-pvc.yaml
kubectl delete -f ~/test-local-storage-pv.yaml
