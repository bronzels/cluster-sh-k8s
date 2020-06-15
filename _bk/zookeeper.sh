#zookeeper
#ec2-user
#git clone https://github.com/pravega/zookeeper-operator.git
wget -c https://github.com/pravega/zookeeper-operator/archive/v0.2.7.tar.gz
tar xzvf v0.2.7.tar.gz
rm -f v0.2.7.tar.gz
ln -s zookeeper-operator-0.2.7 zookeeper-operator
cd zookeeper-operator

file=deploy/crds/zookeeper_v1beta1_zookeepercluster_crd.yaml
cp ${file} ${file}.bk
kubectl create -f deploy/crds/zookeeper_v1beta1_zookeepercluster_crd.yaml
#kubectl delete -f deploy/crds/zookeeper_v1beta1_zookeepercluster_crd.yaml
kubectl get crd -n default
kubectl create -f deploy/all_ns/rbac.yaml
#kubectl delete -f deploy/all_ns/rbac.yaml
kubectl create -f deploy/all_ns/operator.yaml
#kubectl delete -f deploy/all_ns/operator.yaml
kubectl get deploy

file=zk-admin-role.yaml
rm -f $file
cat >> $file << EOF
apiVersion: "zookeeper.pravega.io/v1beta1"
kind: "ZookeeperCluster"
metadata:
  name: "zknh"
spec:
  replicas: 3
EOF
kubectl apply -f zk-admin-role.yaml
#kubectl delete -f zk-admin-role.yaml
