#ubuntu

rev_helm=v3.2.1
wget -c https://get.helm.sh/helm-${rev_helm}-linux-amd64.tar.gz
tar xzvf helm-${rev_helm}-linux-amd64.tar.gz
mv linux-amd64 helm-${rev_helm}-linux-amd64
ln -s helm-${rev_helm}-linux-amd64 helm
chmod a+x $HOME/helm/helm
echo "export KUBECONFIG=$HOME/.kube/config" >> ~/other-env.sh
#echo "export PATH=$PATH:$HOME/helm" >> ~/other-env.sh
sudo ln -s $HOME/helm/helm /usr/bin/helm
#！！！手工，重新登录ubuntu
#helm repo add stable https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts
#helm repo add incubator https://aliacs-app-catalog.oss-cn-hangzhou.aliyuncs.com/charts-incubator/
rm -rf $HOME/.cache/helm
rm -rf $HOME/.config/helm
rm -rf $HOME/.local/share/helm
helm repo add stable https://kubernetes-charts.storage.googleapis.com
helm repo add incubator https://kubernetes-charts-incubator.storage.googleapis.com/
helm repo add bitnami https://charts.bitnami.com/bitnami

rm -rf $HOME/cmstorage
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
#！！！手工，测试直到返回
#{"repositories":[]}
curl http://localhost:30500/v2/_catalog

#以下image用作flink的base image，必须执行
cp ~/source.list.ubuntu.16.04 source.list

docker images|grep ubu16ssh
docker images|grep ubu16ssh|awk '{print $3}'|xargs docker rmi -f
ansible slave -m shell -a"docker images|grep ubu16ssh|awk '{print \$3}'|xargs docker rmi -f"
docker images|grep ubu16ssh

cat << \EOF > Dockerfile.ubu16ssh
FROM ubuntu:16.04

COPY ./sources.list /etc/apt
RUN apt-get update
RUN apt-get install -y openssh-server
RUN sed -i 's@PermitRootLogin prohibit-password@PermitRootLogin yes@g' /etc/ssh/sshd_config
RUN sed -i 's@#PasswordAuthentication yes@PasswordAuthentication yes@g' /etc/ssh/sshd_config
RUN usermod --password $(echo root | openssl passwd -1 -stdin) root
RUN systemctl enable ssh

WORKDIR /

EXPOSE 22

ENTRYPOINT service ssh start && set -e -x && tail -f /dev/null

EOF

docker build -f Dockerfile.ubu16ssh -t master01:30500/bronzels/ubu16ssh:0.1 ./
docker push master01:30500/bronzels/ubu16ssh:0.1

#以上测试可以跳过
:<<EOF
EOF
cat << EOF > ubu16ssh-deploy-svc.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myubu16sshpod
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ubu16ssh
      role: client-cp
  template:
    metadata:
      labels:
        app: ubu16ssh
        role: client-cp
    spec:
      containers:
      - name: ubu16ssh
        image: master01:30500/bronzels/ubu16ssh:0.1
        ports:
        - name: ssh
          containerPort: 22
        resources:
         requests:
           cpu: 4
           memory: 4096Mi
         limits:
           cpu: 8
           memory: 8192Mi
---
apiVersion: v1
kind: Service
metadata:
  name: myubu16sshsvc
  namespace: default
spec:
  selector:
    app: ubu16ssh
    role: client-cp
  type: ClusterIP
  ports:
  - port: 22
    targetPort: 22
EOF

kubectl apply -f ubu16ssh-deploy-svc.yaml
kubectl get pod
kubectl get svc

kubectl run test-ubu16ssh1 -ti --image=master01:30500/bronzels/ubu16ssh:0.1 --rm=true --restart=Never -- bash
  ssh -p 22 root@myubu16sshsvc

kubectl delete -f ubu16ssh-deploy-svc.yaml
