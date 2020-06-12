cd ~/charts/incubator/zookeeper/

for((i=0;i<=2;i++));
do
ansible slave -i /etc/ansible/hosts-ubuntu -m shell -a"rm -rf ~/mypv/zk${i};mkdir ~/mypv/zk${i}"
ansible slave -i /etc/ansible/hosts-ubuntu -m shell -a"chmod 777 ~/mypv/zk${i}"
done

file=local-storage-pv-zk.yaml
rm -f $file
cat >> $file << EOF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: localpath-zk
spec:
  capacity:
    storage: 5Gi
  volumeMode: Filesystem
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Delete
  storageClassName: local-storage
  local:
    path: /home/ubuntu/mypv/zk
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
for((i=0;i<=2;i++));
do
cp local-storage-pv-zk.yaml local-storage-pv-zk${i}.yaml
sed -i "s@localpath-zk@localpath-zk${i}@g" local-storage-pv-zk${i}.yaml
sed -i "s@/home/ubuntu/mypv/zk@/home/ubuntu/mypv/zk${i}@g" local-storage-pv-zk${i}.yaml
kubectl apply -f local-storage-pv-zk${i}.yaml
done
kubectl get pv -n default

file=values.yaml
cp ${file} ${file}.bk
sed -i 's@# storageClass: "-"@storageClass: "local-storage"@g' $file

helm install -f values.yaml zknh .

helm uninstall zknh
kubectl delete -f ~/charts/incubator/zookeeper/local-storage-pv-zk0.yaml
kubectl delete -f ~/charts/incubator/zookeeper/local-storage-pv-zk1.yaml
kubectl delete -f ~/charts/incubator/zookeeper/local-storage-pv-zk2.yaml
kubectl delete pvc data-zknh-zookeeper-${i} -n default
for((i=0;i<=2;i++));
do
kubectl delete pvc data-zknh-zookeeper-${i} -n default
ansible slave -i /etc/ansible/hosts-ubuntu -m shell -a"rm -rf ~/mypv/zk${i}/*"
done

kubectl get all -l app=zookeeper
kubectl get pv -n default
kubectl get pvc -n default
kubectl get pod -n default
kubectl describe pvc data-zknh-zookeeper-0 -n default
kubectl describe pvc data-zknh-zookeeper-1 -n default
kubectl describe pvc data-zknh-zookeeper-2 -n default
kubectl describe pod zknh-zookeeper-0 -n default
kubectl describe pod zknh-zookeeper-1 -n default
kubectl describe pod zknh-zookeeper-2 -n default

for((i=0;i<=2;i++));
do
ansible slave -i /etc/ansible/hosts-ubuntu -m shell -a"ls ~/mypv/zk${i}"
done


kubectl exec zknh-zookeeper-0 -- bin/zkCli.sh create /foo bar
kubectl exec zknh-zookeeper-2 -- bin/zkCli.sh get /foo
kubectl exec zknh-zookeeper-1 -- bin/zkCli.sh create /foo2 bar2
kubectl exec zknh-zookeeper-1 -- bin/zkCli.sh get /foo2

kubectl delete pod bbox
kubectl run --attach bbox --image=busybox --restart=Never -- sh -c 'while true; do for i in 0 1 2; do echo zk-${i} $(echo stats | nc zknh-zookeeper-${i}.zknh-zookeeper-headless:2181 | grep Mode); sleep 1; done; done'
