sudo ansible slavek8s -m shell -a"apt-get install -y lvm2"
sudo ansible slavek8s -m shell -a"modprobe rbd"

git clone https://github.com/rook/rook.git
cd ~/rook/
git checkout release-1.3

cd ~/rook/cluster/examples/kubernetes/ceph

#开始安装前确保所有slave都在线ready
kubectl get node -n kube-system

kubectl create -f common.yaml
#kubectl delete -f common.yaml
kubectl create -f operator.yaml
#kubectl delete -f operator.yaml
file=cluster.yaml
cp ${file} ${file}.bk
ansible slavek8s -i /etc/ansible/hosts-ubuntu -m shell -a"mkdir $HOME/rook"
ansible slavek8s -i /etc/ansible/hosts-ubuntu -m shell -a"ls $HOME/rook/"
sed -i "s@dataDirHostPath: /var/lib/rook@dataDirHostPath: $HOME/rook/ceph@g" ${file}
#root
sudo ansible slavek8s -m shell -a"fdisk -l|grep '2 TiB'"
#！！！手工，找到数据盘对应设备名，填入到一下sed命令
sed -i "s@#deviceFilter:@deviceFilter: "^nvme1n1"@g" ${file}
sed -i "s@count: 3@count: 4@g" ${file}
kubectl create -f cluster.yaml
#kubectl delete -f cluster.yaml
#！！！，至少等15分钟
# 有error/crashbackoff都不要担心，硬盘初始化需要时间。
# 要等到rook-ceph-osd-prepare/4个都complete，rook-ceph-osd/4个都在1/1 running才进行下一步
# 如果出现错误，不要删除下面的storageclass，有可能要等待很长时间没有提示，如果ssh应该跳板机中断，那就既不能删除又不能新增storageclass了。

file=csi/rbd/storageclass.yaml
cp ${file} ${file}.bk
sed -i "s@csi.storage.k8s.io/fstype: ext4@csi.storage.k8s.io/fstype: xfs@g" ${file}
kubectl create -f csi/rbd/storageclass.yaml
#kubectl delete -f csi/rbd/storageclass.yaml
# 如果出现错误，不要删除下面的storageclass，有可能要等待很长时间没有提示，如果ssh应该跳板机中断，那就既不能删除又不能新增storageclass了。
kubectl patch storageclass rook-ceph-block -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
kubectl get storageclass

kubectl get service -n rook-ceph
kubectl get pod -n rook-ceph

kubectl get svc -n rook-ceph |grep mgr-dashboard
kubectl create -f dashboard-external-https.yaml
#kubectl delete -f dashboard-external-https.yaml
kubectl get service -n rook-ceph|grep rook-ceph-mgr-dashboard-external-https
#！！！手工，找到service映射的nodeport
curl https://localhost:31350/#/login
#！！！手工，账户admin，密码以下命令生成
kubectl -n rook-ceph get secret rook-ceph-dashboard-password -o jsonpath='{.data.password}'  |  base64 --decode
#admin
#_VIbW5C@2*[?,<VT%lLX

kubectl create -f toolbox.yaml
#kubectl delete -f toolbox.yaml
#kubectl -n rook-ceph get pod -l "app=rook-ceph-tools" -o wide | grep rook-ceph-tools | awk '{print $1}' | xargs -n1 -i{} kubectl -n rook-ceph exec -it {} bash
#！！！手工，检查ceph集群状态
kubectl -n rook-ceph exec -it `kubectl -n rook-ceph get pod -l "app=rook-ceph-tools" -o wide | grep rook-ceph-tools | awk '{print $1}'` -- bash
  #ceph status
  #ceph df
  #ceph osd status
  #rados df
  #ceph osd pool create test_pool 64
  #ceph osd pool delete test_pool test_pool --yes-i-really-really-mean-it
  #exit

kubectl create -f monitoring/
#kubectl delete -f monitoring/
kubectl -n rook-ceph get pod |grep prometheus-rook
kubectl -n rook-ceph get svc |grep rook-prometheus
curl http://localhost:30900/graph

cat << EOF > busy-box-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: busybox-pvc
  namespace: default
spec:
  storageClassName: rook-ceph-block
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1024Mi
EOF
kubectl create -f busy-box-pvc.yaml
#kubectl delete -f busy-box-pvc.yaml
kubectl get pvc
kubectl get pv
kubectl -n rook-ceph exec -it rook-ceph-tools-84d6784856-75jck bash
  #rbd list -p replicapool
  #rbd info -p replicapool csi-vol-d30eb544-a609-11ea-bf74-926355af23ab
  #ceph df
  #exit

cat << EOF > busy-box-test1.yaml
apiVersion: v1
kind: Pod
metadata:
  name: busy-box-test1
  namespace: default
spec:
  restartPolicy: OnFailure
  containers:
  - name: busy-box-test1
    image: busybox
    volumeMounts:
    - name: busy-box-test-pv1
      mountPath: /mnt/busy-box
    command: ["sleep", "60000"]
  volumes:
  - name: busy-box-test-pv1
    persistentVolumeClaim:
      claimName: busybox-pvc
EOF
kubectl create -f busy-box-test1.yaml
#kubectl delete -f busy-box-test1.yaml
kubectl get pod -n default
kubectl exec -it busy-box-test1 /bin/sh
  #echo "This message write from busy-box-test1" > /mnt/busy-box/message.txt
  #ls /mnt/busy-box/
  #exit

kubectl delete pod/busy-box-test1

cat << EOF > busy-box-test2.yaml
apiVersion: v1
kind: Pod
metadata:
  name: busy-box-test2
  namespace: default
spec:
  restartPolicy: OnFailure
  containers:
  - name: busy-box-test2
    image: busybox
    volumeMounts:
    - name: busy-box-test-pv2
      mountPath: /mnt/busy-box
    command: ["sleep", "60000"]
  volumes:
  - name: busy-box-test-pv2
    persistentVolumeClaim:
      claimName: busybox-pvc
EOF
kubectl create -f busy-box-test2.yaml
kubectl get pod -n default
kubectl exec -it busy-box-test2 /bin/sh
  #cat /mnt/busy-box/message.txt
  #exit

kubectl delete -f busy-box-test2.yaml
#kubectl get pvc -n default|grep busybox|awk '{print $1}'|xargs kubectl -n default delete pvc
