cd

#wget -c https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta8/aio/deploy/recommended.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta8/aio/deploy/recommended.yaml
#kubectl delete -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta8/aio/deploy/recommended.yaml

#refer to https://www.e-learn.cn/content/qita/2653907
kubectl -n kubernetes-dashboard edit service kubernetes-dashboard
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
#eyJhbGciOiJSUzI1NiIsImtpZCI6InVrTEV4MzFnLXdFR25ydXdEZ3BSNjhxcWpwd2RNZEJXU3R6YVo3MndEUUEifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJrdWJlcm5ldGVzLWRhc2hib2FyZCIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJhZG1pbi10b2tlbi1uNDR6ZCIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50Lm5hbWUiOiJhZG1pbiIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50LnVpZCI6IjRiMWZiZDdlLWI4YzQtNGY2NC1hZmExLWE0MGVhNWZkZWQ4NSIsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDprdWJlcm5ldGVzLWRhc2hib2FyZDphZG1pbiJ9.eo9X6eFE8mOxJHht7iVczQpsup1GWmDQb6T7gLsv-IRWc85xunCxnGbtSdQvoCtzBchxXJZQcUfKCwIdbASWoWlhGvyoQ1Kqi5fKgYeBYkBirpqAQOQ8omoJHMBjZAkf1VZqG1gSL48hZpkXU1zUSpnMrwvqP75fiU80I85yLsUUxlbtxedVQMAZg56ekzIp3-b_c4w6U_bsK9x2SMiCB3RNB3VdjLhB35K_kvgdWqXaVSWEPYxIctcuC7UhH1dwbCCDXgI-QaEalYrEL0rI74DIvumF3-3gu5PTJJewkf49P0W0VL4_OvjSQ_kNOL1p1lQnYHgAE2H6y-J3dmPeCA
#！！！手工，用firefox打开https://master01:32576，把上面的token填入提示

