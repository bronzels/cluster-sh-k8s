wget https://github.com/kubernetes/kubernetes/raw/master/cluster/addons/dns/nodelocaldns/nodelocaldns.yaml
cp nodelocaldns.yaml nodelocaldns.yaml.bk
#cp nodelocaldns.yaml.bk nodelocaldns.yaml
k get svc -n kube-system | grep kube-dns | awk '{ print $3 }'
#linux
sed -i \
#mac
cat nodelocaldns.yaml | grep 'k8s-dns-node-cache\|__PILLAR__DNS__SERVER__\|__PILLAR__LOCAL__DNS__\|__PILLAR__DNS__DOMAIN__'
sed -i "" \
"s@registry.k8s.io/dns/k8s-dns-node-cache:1.22.13@registry.cn-hangzhou.aliyuncs.com/bronzels/registry.k8s.io-dns-k8s-dns-node-cache-1.22.13:1.0@g
s/__PILLAR__DNS__SERVER__/10.96.0.10/g
s/__PILLAR__LOCAL__DNS__/169.254.20.10/g
s/__PILLAR__DNS__DOMAIN__/cluster.local/g" nodelocaldns.yaml
cat nodelocaldns.yaml | grep 'k8s-dns-node-cache\|10.96.0.10\|169.254.20.10\|cluster.local'

#在git私仓创建仓库registry.k8s.io/dns/k8s-dns-node-cache:1.22.13
git clone git@github.com:bronzels/registry.k8s.io-dns-k8s-dns-node-cache-1.22.13.git
cd registry.k8s.io-dns-k8s-dns-node-cache-1.22.13
cat > Dockerfile << EOF
FROM registry.k8s.io/dns/k8s-dns-node-cache:1.22.13
EOF
git add ./
git commit -m "1st time setup"
git push
#参考文章在阿里云私仓构建公开的仓库
#https://copyfuture.com/blogs-details/202204151538240825
#https://cr.console.aliyun.com/cn-hangzhou/instance/repositories

kubectl apply -f nodelocaldns.yaml
#kubectl delete -f nodelocaldns.yaml
k get pod -n kube-system | grep node-local-dns

