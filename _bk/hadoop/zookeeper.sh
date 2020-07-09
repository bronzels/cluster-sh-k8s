helm install myzk -n hadoop \
  --set image.tag=3.5.8 \
  incubator/zookeeper
:<<EOF
helm uninstall myzk -n hadoop
kubectl get pvc -n hadoop | awk '{print $1}' | grep data-myzk- | xargs kubectl delete pvc -n hadoop

kubectl get pod -n hadoop -o wide
kubectl get pvc -n hadoop -o wide
kubectl get svc -n hadoop -o wide

kubectl exec myzk-zookeeper-0 -n hadoop -- bin/zkCli.sh create /foo bar
kubectl exec myzk-zookeeper-0 -n hadoop -- bin/zkCli.sh get /foo
EOF
:<<EOF
NOTES:
Thank you for installing ZooKeeper on your Kubernetes cluster. More information
about ZooKeeper can be found at https://zookeeper.apache.org/doc/current/

Your connection string should look like:
  myzk-zookeeper-0.myzk-zookeeper-headless:2181,myzk-zookeeper-1.myzk-zookeeper-headless:2181,...

You can also use the client service myzk-zookeeper:2181 to connect to an available ZooKeeper server.
EOF
#myzk-zookeeper-0.myzk-zookeeper-headless:2181,myzk-zookeeper-1.myzk-zookeeper-headless:2181,myzk-zookeeper-2.myzk-zookeeper-headless:2181
#myzk-zookeeper:2181

