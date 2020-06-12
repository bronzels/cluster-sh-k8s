kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta8/aio/deploy/recommended.yaml

#refer to https://www.e-learn.cn/content/qita/2653907
# kubectl -n kubernetes-dashboard edit service kubernetes-dashboard
# 在 ports下面添加nodePort: 32576，将 type: ClusterIP改为NodePort
file=~/admin-role.yaml
rm -f $file
cat >> $file << EOF
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
   name: admin
   annotations:
     rbac.authorization.kubernetes.io/autoupdate: "true"
roleRef:
   kind: ClusterRole
   name: cluster-admin
   apiGroup: rbac.authorization.k8s.io
subjects:
 - kind: ServiceAccount
   name: admin
   namespace: kubernetes-dashboard
---
apiVersion: v1
kind: ServiceAccount
metadata:
   name: admin
   namespace: kubernetes-dashboard
   labels:
     kubernetes.io/cluster-service: "true"
     addonmanager.kubernetes.io/mode: Reconcile
EOF
kubectl apply -f ~/admin-role.yaml
#kubectl delete -f ~/admin-role.yaml
kubectl get pod -n kubernetes-dashboard
kubectl get svc -n kubernetes-dashboard
kubectl -n kubernetes-dashboard get secret|grep admin-token |awk '{print $1}'|xargs kubectl -n kubernetes-dashboard describe secret
kubectl -n kubernetes-dashboard describe secret admin-token-9dk6d
#eyJhbGciOiJSUzI1NiIsImtpZCI6IjE4SWJRYjdBVDZpU2tnRXVMWWYzSHBIUTBhZVZRalQtSlFraUw1WGtFbE0ifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJrdWJlcm5ldGVzLWRhc2hib2FyZCIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJhZG1pbi10b2tlbi05ZGs2ZCIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50Lm5hbWUiOiJhZG1pbiIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50LnVpZCI6IjczMmE0ZGNlLTAxODktNDUzOS04MjRlLTA1OWIzZGM2ODA1YyIsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDprdWJlcm5ldGVzLWRhc2hib2FyZDphZG1pbiJ9.pVZ2j2Ve6j5_GgYMlSCMqSYmsWlCUBjLjsYB0S2lNR3Y-cR3ks6TXgwMBbLNs-hoMF40hvc-7a2fkNx6Ud8vSHVrhpJoIRdGPlxY-L8S0oil0lAwa_-LZqux9_DjfGlZll28CmQxmGTRQhC8vWAhH1jPZfO9kYPEghhctFkgMaF8mu_hnMho0Yj48sbY61WYbNuRIfZXJmR1hZBLTnr4AmpAHuWJkyBfNsz-HqfSG4jovyPhmwb61loyCJjslqJ3OU3YChDimgZCX5FwB758BeyV1CXzNC2xEiQiURn9PdvyPjYLIg76cyKRiL_GMh8E7GYlG0lallTjwFLExMjGyw
#！！！手工，用firefox打开https://master01:32576，把上面的token填入提示

