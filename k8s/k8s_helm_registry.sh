#ubuntu

rev_helm=v3.9.0
wget -c https://get.helm.sh/helm-${rev_helm}-linux-amd64.tar.gz
tar xzvf helm-${rev_helm}-linux-amd64.tar.gz
mv linux-amd64 helm-${rev_helm}-linux-amd64
ln -s helm-${rev_helm}-linux-amd64 helm
chmod a+x $HOME/helm/helm
echo "export KUBECONFIG=$HOME/.kube/config" >> ~/other-env.sh
#echo "export PATH=$PATH:$HOME/helm" >> ~/other-env.sh
sudo ln -s $HOME/helm/helm /usr/bin/helm
source ~/.bashrc
#helm repo add stable https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts
#helm repo add incubator https://aliacs-app-catalog.oss-cn-hangzhou.aliyuncs.com/charts-incubator/
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

