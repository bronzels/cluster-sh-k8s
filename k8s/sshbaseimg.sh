#以下image用作flink的base image，必须执行
#cp ~/sources.list.ubuntu.16.04 sources.list

docker images|grep ubu16ssh
docker images|grep ubu16ssh|awk '{print $3}'|xargs docker rmi -f
ansible slave -m shell -a"docker images|grep ubu16ssh|awk '{print \$3}'|xargs docker rmi -f"
docker images|grep ubu16ssh

#COPY ./sources.list /etc/apt
cat << \EOF > Dockerfile.ubu16ssh
FROM ubuntu:16.04

RUN apt-get update
RUN apt-get install -y openssh-server
RUN sed -i 's@PermitRootLogin prohibit-password@PermitRootLogin yes@g' /etc/ssh/sshd_config
RUN sed -i 's@#PasswordAuthentication yes@PasswordAuthentication yes@g' /etc/ssh/sshd_config
RUN usermod --password $(echo root | openssl passwd -1 -stdin) root
RUN systemctl enable ssh

WORKDIR /

EXPOSE 22

ENTRYPOINT service ssh start && set -e -x && tail -f /dev/null

EOF

docker build -f Dockerfile.ubu16ssh -t master01:30500/bronzels/ubu16ssh:0.1 ./
docker push master01:30500/bronzels/ubu16ssh:0.1

#以上测试可以跳过
:<<EOF
EOF
cat << EOF > ubu16ssh-deploy-svc.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myubu16sshpod
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ubu16ssh
      role: client-cp
  template:
    metadata:
      labels:
        app: ubu16ssh
        role: client-cp
    spec:
      containers:
      - name: ubu16ssh
        image: master01:30500/bronzels/ubu16ssh:0.1
        ports:
        - name: ssh
          containerPort: 22
        resources:
         requests:
           cpu: 4
           memory: 4096Mi
         limits:
           cpu: 8
           memory: 8192Mi
---
apiVersion: v1
kind: Service
metadata:
  name: myubu16sshsvc
  namespace: default
spec:
  selector:
    app: ubu16ssh
    role: client-cp
  type: ClusterIP
  ports:
  - port: 22
    targetPort: 22
EOF

kubectl apply -f ubu16ssh-deploy-svc.yaml
kubectl get pod
kubectl get svc

kubectl run test-myubussh -ti --image=praqma/network-multitool --rm=true --restart=Never -- bash
  ssh -p 22 root@myubu16sshsvc

kubectl delete -f ubu16ssh-deploy-svc.yaml
