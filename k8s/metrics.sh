if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Mac detected."
    #mac
    MYHOME=/Volumes/data
    SED=gsed
else
    echo "Assuming linux by default."
    #linux
    MYHOME=~
    SED=sed
fi

file=metrics-server-components.yaml
wget https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml -O ${file}
$SED -i 's/k8s.gcr.io\/metrics-server/registry.cn-hangzhou.aliyuncs.com\/google_containers/g' ${file}
$SED -i '/        - --metric-resolution=15s/a\        - --kubelet-insecure-tls\' ${file}

kubectl apply -f ${file}

