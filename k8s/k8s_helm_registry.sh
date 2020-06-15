#ubuntu

rev_helm=v3.2.1
wget -c https://get.helm.sh/helm-${rev_helm}-linux-amd64.tar.gz
tar xzvf helm-${rev_helm}-linux-amd64.tar.gz
mv linux-amd64 helm-${rev_helm}-linux-amd64
ln -s helm-${rev_helm}-linux-amd64 helm
chmod a+x $HOME/helm/helm
echo "export KUBECONFIG=$HOME/.kube/config" >> ~/.bashrc
echo "export PATH=$PATH:$HOME/helm" >> ~/.bashrc
#！！！手工，重新登录ubuntu
#helm repo add stable https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts
#helm repo add incubator https://aliacs-app-catalog.oss-cn-hangzhou.aliyuncs.com/charts-incubator/
helm repo add stable https://kubernetes-charts.storage.googleapis.com
helm repo add incubator https://kubernetes-charts-incubator.storage.googleapis.com/
helm repo add bitnami https://charts.bitnami.com/bitnami

mkdir -rf $HOME/cmstorage
mkdir -p $HOME/cmstorage/charts
docker run --name=chartmuseum \
           --restart=always -it -d \
           -p 8879:8080 \
           -v $HOME/cmstorage/charts:/charts \
           -e STORAGE=local \
           -e STORAGE_LOCAL_ROOTDIR=/charts \
           chartmuseum/chartmuseum:v0.12.0
helm repo add local http://localhost:8879
#curl --data-binary @./test-0.1.0.tgz http://localhost:8879/api/charts
#mv test-0.1.0.tgz ~/cmstorage/charts/

git clone https://github.com/helm/charts.git

#helm install dkreg stable/docker-registry
#kubectl -n default port-forward --address 0.0.0.0 $POD_NAME 9090:5000
cd ~/charts/stable/docker-registry
file=values.yaml
cp ${file} ${file}.bk
sed -i 's@type: ClusterIP@type: NodePort@g' ${file}
sed -i 's@# nodePort:@nodePort: 30500@g' ${file}
helm install -f values.yaml dkreg .
#helm uninstall dkreg
curl http://master01:30500/v2/_catalog

cat << \EOF > Dockerfile-testredis.yaml
FROM redis:4.0-alpine
MAINTAINER bronzels@hotmail.com

EOF
docker build -f Dockerfile-testredis.yaml -t bigdata/testredis:0.1 ./
docker tag bigdata/testredis:0.1 master01:30500/bigdata/testredis:0.1
docker push master01:30500/bigdata/testredis:0.1
curl http://master01:30500/v2/_catalog

cat << EOF > ~/redis-deploy-testsvc.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myrdtestpod
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: testredis
      role: mem-cache
  template:
    metadata:
      labels:
        app: testredis
        role: mem-cache
    spec:
      containers:
      - name: testredis
        image: master01:30500/bigdata/testredis:0.1
        ports:
        - name: testredis
          containerPort: 6379
---
apiVersion: v1
kind: Service
metadata:
  name: myrdtestsvc
  namespace: default
spec:
  selector:
    app: testredis
    role: mem-cache
  type: ClusterIP
  ports:
  - port: 6379
    targetPort: 6379
EOF
kubectl apply -f ~/redis-deploy-testsvc.yaml
kubectl get pod
kubectl get svc

kubectl -n default run test-redis -ti --image=redis --rm=true --restart=Never -- redis-cli -h myrdtestsvc set fool bar
kubectl -n default run test-redis -ti --image=redis --rm=true --restart=Never -- redis-cli -h myrdtestsvc get fool
kubectl -n default run test-redis -ti --image=redis --rm=true --restart=Never -- redis-cli -h myrdtestsvc set fool2 bar2
kubectl -n default run test-redis -ti --image=redis --rm=true --restart=Never -- redis-cli -h myrdtestsvc get fool2

kubectl delete -f ~/redis-deploy-testsvc.yaml
