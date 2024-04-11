if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Mac detected."
    #mac
    DATAHOME=/Volumes/data/Applications
    os=darwin
    SED=gsed
else
    echo "Assuming linux by default."
    #linux
    DATAHOME=~
    os=linux
    SED=sed
fi

mkdir test
cd test
cat > test-deployment.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: service-test
spec:
  replicas: 4
  selector:
    matchLabels:
      app: service_test_pod
  template:
    metadata:
      labels:
        app: service_test_pod
    spec:
      containers:
      - name: simple-http
        image: python:2.7
        imagePullPolicy: IfNotPresent
        command: ["/bin/bash"]
        args: ["-c", "echo \"<p>Hello from \$(hostname)</p>\" > index.html; python -m SimpleHTTPServer 8080"]
        ports:
        - name: http
          containerPort: 8080
EOF
cat > test-service.yaml << EOF
apiVersion: v1
kind: Service
metadata:
  name: service-test
spec:
  #clusterIP: None
  ports:
  - port: 8088
    targetPort: 8080
  selector:
    app: service_test_pod
EOF
cd ..

kubectl apply -f test/test-deployment.yaml
kubectl apply -f test/test-service.yaml

kubectl delete -f test/test-deployment.yaml
kubectl delete -f test/test-service.yaml

kubectl get svc -o wide
kubectl get pod -o wide

kubectl run curl-json -it --image=radial/busyboxplus:curl --restart=Never --rm -- /bin/sh
kubectl run curl-pycentos7 -it --image=harbor.my.org:1080/base/python:3.8-centos7-netutil --restart=Never --rm -- /bin/bash

kubectl create secret docker-registry harbor-secret --namespace=default --docker-server=harbor.my.org:1080 --docker-username=admin --docker-password=Harbor12345
#kubectl describe secret harbor-secret

# 查看k8s集群中运行的coredns pod
kubectl  get pod -n kube-system | grep coredns
# 编辑coredns的配置，coredfile中添加自定义域名解析配置
kubectl get configmap -n kube-system coredns -o yaml > coredns-config.yaml
file=coredns-config.yaml
cp ${file} ${file}.bk
cat > hosts-added << EOF
        hosts {
           192.168.3.14 dtpct
           192.168.3.6 mdlapubu
           192.168.3.103 mdubu
           192.168.3.9 mmubu
           192.168.3.9 harbor.my.org
           192.168.3.9 pypi.my.org
           fallthrough
        }
EOF
$SED -i '/        prometheus :9153/r hosts-added' ${file}
kubectl apply -f coredns-config.yaml
rm -f hosts-added
kubectl get configmap -n kube-system coredns -o yaml
kubectl get pod -n kube-system |grep coredns |awk '{print $1}'| xargs kubectl delete pod "$1" -n kube-system --force --grace-period=0

kubectl run curl-pyseccentos7 -it \
  --image=harbor.my.org:1080/basesec/python:3.8-centos7-netutil \
  --image-pull-policy="IfNotPresent" \
  --overrides='{ "spec": { "template": { "spec": { "imagePullSecrets": [{"name": "harbor-secret"}] } } } }' \
  --restart=Never --rm -- /bin/bash


