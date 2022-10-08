cat >> test-deployment.yaml << EOF
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
        args: ["-c", "echo \"<p>Hello from $(hostname)</p>\" > index.html; python -m SimpleHTTPServer 8080"]
        ports:
        - name: http
          containerPort: 8080
EOF
kubectl apply -f test-deployment.yaml

cat >> test-service.yaml << EOF
apiVersion: v1
kind: Service
metadata:
  name: service-test
spec:
  #clusterIP: None
  ports:
  - port: 8080
    targetPort: 8088
  selector:
    app: service_test_pod
EOF
kubectl apply -f test-service.yaml

kubectl get svc -o wide

kubectl run curl-json -n chubaofs -it --image=radial/busyboxplus:curl --restart=Never --rm -- /bin/sh


for i in `seq 4`; do curl 10.101.90.210:8088; done

