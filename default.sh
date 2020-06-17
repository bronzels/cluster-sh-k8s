
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/v0.39.0/bundle.yaml
#kubectl delete -f https://raw.githubusercontent.com/coreos/prometheus-operator/v0.39.0/bundle.yaml
kubectl get pod |grep prometheus
