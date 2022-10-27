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
kubectl apply -f test-deployment.yaml

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
kubectl apply -f test-service.yaml

kubectl get svc -o wide
kubectl get pod -o wide

kubectl run curl-json -it --image=radial/busyboxplus:curl --restart=Never --rm -- /bin/sh
kubectl run curl-pycentos7 -it --image=harbor.my.org:1080/base/python:3.8-centos7-netutil --restart=Never --rm -- /bin/bash

kubectl create secret docker-registry harbor-secret --namespace=default --docker-server=harbor.my.org:1080 --docker-username=admin --docker-password=Harbor12345
kubectl describe secret harbor-secret

kubectl run curl-pyseccentos7 -it \
  --image=harbor.my.org:1080/basesec/python:3.8-centos7-netutil \
  --image-pull-policy="IfNotPresent" \
  --overrides='{ "spec": { "template": { "spec": { "imagePullSecrets": [{"name": "harbor-secret"}] } } } }' \
  --restart=Never --rm -- /bin/bash

