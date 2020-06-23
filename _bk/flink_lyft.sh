kubectl create -f https://raw.githubusercontent.com/lyft/flinkk8soperator/v0.5.0/deploy/crd.yaml
kubectl create -f https://raw.githubusercontent.com/lyft/flinkk8soperator/v0.5.0/deploy/namespace.yaml
kubectl create -f https://raw.githubusercontent.com/lyft/flinkk8soperator/v0.5.0/deploy/role.yaml
kubectl create -f https://raw.githubusercontent.com/lyft/flinkk8soperator/v0.5.0/deploy/role-binding.yaml

mkdir ~/flinkk8soperator
cd ~/flinkk8soperator

wget https://raw.githubusercontent.com/lyft/flinkk8soperator/v0.5.0/deploy/config.yaml

kubectl create -f config.yaml

kubectl create -f https://raw.githubusercontent.com/lyft/flinkk8soperator/v0.5.0/deploy/flinkk8soperator.yaml

kubectl create -f https://raw.githubusercontent.com/lyft/flinkk8soperator/v0.5.0/examples/wordcount/flink-operator-custom-resource.yaml

kubectl get flinkapplication.flink.k8s.io -n flink-operator wordcount-operator-example -o yaml
kubectl describe flinkapplication.flink.k8s.io -n flink-operator wordcount-operator-example
