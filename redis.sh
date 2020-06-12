rm -rf ~/redis
mkdir ~/redis

cat << EOF > ~/redis/redis-deploy-svc.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myrdpod
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
      role: mem-cache
  template:
    metadata:
      labels:
        app: redis
        role: mem-cache
    spec:
      containers:
      - name: redis
        image: redis:4.0-alpine
        ports:
        - name: redis
          containerPort: 6379
---
apiVersion: v1
kind: Service
metadata:
  name: myrdsvc
  namespace: default
spec:
  selector:
    app: redis
    role: mem-cache
  type: ClusterIP
  ports:
  - port: 6379
    targetPort: 6379
EOF
kubectl apply -f ~/redis/redis-deploy-svc.yaml
#kubectl delete -f ~/redis/redis-deploy-svc.yaml
kubectl get pod
kubectl get svc

kubectl -n default run test-redis -ti --image=redis --rm=true --restart=Never -- redis-cli -h myrdsvc set fool bar
kubectl -n default run test-redis -ti --image=redis --rm=true --restart=Never -- redis-cli -h myrdsvc get fool
kubectl -n default run test-redis -ti --image=redis --rm=true --restart=Never -- redis-cli -h myrdsvc set fool2 bar2
kubectl -n default run test-redis -ti --image=redis --rm=true --restart=Never -- redis-cli -h myrdsvc get fool2

