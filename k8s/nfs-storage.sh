helm repo add stable https://charts.helm.sh/stable
helm repo update
kubectl create ns nfs
#ubuntu
ansible all -m shell -a"apt install -y nfs-common"
#centos
ansible all -m shell -a"yum install -y nfs-utils"
sudo rm -rf /Volumes/data/nfs/*
helm install my stable/nfs-client-provisioner --set nfs.server=192.168.3.9 --set nfs.path=/Volumes/data/nfs -n nfs
helm uninstall my -n nfs
kubectl get all -n nfs
kubectl get sc

#k8s master
:<<EOF
修改/etc/kubernetes/manifests/kube-apiserver.yaml
在 - --tls-private-key-file=/etc/kubernetes/pki/apiserver.key下面添加如下：
- --feature-gates=RemoveSelfLink=false
EOF
#apiserver连接会断开大概1分钟
kubectl get pod -n kube-system -o wide
#如果apiserver pod状态不正常，删除重启
kubectl delete pod kube-apiserver-dtpct -n kube-system
kubectl get pod -n kube-system -o wide

mkdir nfs
cat << \EOF > test/nfs-test-pvc.yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: nfs-test-claim
  annotations:
    volume.beta.kubernetes.io/storage-class: "nfs-client"
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Mi
EOF
cat << \EOF > test/nfs-test-pod.yaml
kind: Pod
apiVersion: v1
metadata:
  name: nfs-test
spec:
  containers:
  - name: test-pod
    image: busybox:1.24
    command:
      - "/bin/sh"
    args:
      - "-c"
      - "echo 'success' > /mnt/SUCCESS && cat /mnt/SUCCESS && exit 0 || exit 1"
    volumeMounts:
      - name: nfs-pvc
        mountPath: "/mnt"
  restartPolicy: "Never"
  volumes:
    - name: nfs-pvc
      persistentVolumeClaim:
        claimName: test-claim
EOF
kubectl apply -f test/nfs-test-pvc.yaml
kubectl apply -f test/nfs-test-pod.yaml

kubectl logs nfs-test
success
kubectl delete pod nfs-test --force --grace-period=0
kubectl apply -f nfs-test-pod.yaml
kubectl logs nfs-test
success
success

kubectl delete -f test/nfs-test-pvc.yaml
kubectl delete -f test/nfs-test-pod.yaml

ls /Volumes/data/nfs
rm -rf /Volumes/data/nfs/archived-default-test-claim-pvc-*
