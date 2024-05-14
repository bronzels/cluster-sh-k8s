if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Mac detected."
    #mac
    MYHOME=/Volumes/data
    BININSTALLED=/Users/apple/bin
    os=darwin
    SED=gsed
else
    echo "Assuming linux by default."
    #linux
    MYHOME=~
    BININSTALLED=~/bin
    os=linux
    SED=sed
fi

#安装
wget -c https://raw.githubusercontent.com/rancher/local-path-provisioner/master/deploy/local-path-storage.yaml
file=local-path-storage.yaml
cp ${file} ${file}.bk
$SED -i "s@/opt/local-path-provisioner@/data0/local-path-provisioner@g" ${file}
ansible all -m shell -a"rm -rf /data0/local-path-provisioner;mkdir /data0/local-path-provisioner"
kubectl apply -f local-path-storage.yaml

kubectl delete -f local-path-storage.yaml
kubectl get pod -n local-path-storage  |grep -v Running |awk '{print $1}'| xargs kubectl delete pod "$1" -n local-path-storage  --force --grace-period=0

kubectl logs -n local-path-storage `kubectl get pod -n local-path-storage | awk '{print $1}'`
kubectl logs -n local-path-storage `kubectl get pod -n local-path-storage | grep Running | awk '{print $1}'`

#使用
cd test

wget -c https://raw.githubusercontent.com/rancher/local-path-provisioner/master/examples/pvc/pvc.yaml -O test/local-path-pvc.yaml
wget -c https://raw.githubusercontent.com/rancher/local-path-provisioner/master/examples/pod/pod.yaml -O test/local-path-pod.yaml

kubectl apply -f test/local-path-pvc.yaml
kubectl apply -f test/local-path-pod.yaml

kubectl logs volume-test
kubectl exec -it volume-test -- /bin/sh
  echo success > /data/test

kubectl delete -f test/local-path-pod.yaml
kubectl apply -f test/local-path-pod.yaml
kubectl exec -it volume-test -- /bin/sh
  cat /data/test

#测试
kubectl delete -f test/local-path-pod.yaml
kubectl delete -f test/local-path-pvc.yaml