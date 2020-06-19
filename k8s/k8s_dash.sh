cd

#wget -c https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta8/aio/deploy/recommended.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta8/aio/deploy/recommended.yaml

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
#！！！手工，查的随机生成的NodePort端口
kubectl -n kubernetes-dashboard get secret|grep admin-token |awk '{print $1}'|xargs kubectl -n kubernetes-dashboard describe secret
#eyJhbGciOiJSUzI1NiIsImtpZCI6Ilc1R054aWpOMjFqbWJUZ1F4TzZGcGo5a1ItY05fX3JyMmFHWVAwb2JaWkUifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJrdWJlcm5ldGVzLWRhc2hib2FyZCIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJhZG1pbi10b2tlbi1xajRndiIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50Lm5hbWUiOiJhZG1pbiIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50LnVpZCI6ImU5NWY0M2Q3LTI0MWEtNDliNC1iYmZkLWQ2YTU0YjNjNmVlZSIsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDprdWJlcm5ldGVzLWRhc2hib2FyZDphZG1pbiJ9.iKhNYrc_0axIhZRvttQi21PbK4jI7lbiWwy56z9dNMIBn33SPQJbfCZP2iz2XMFvoh92wdOYpKI6T8ATnv6hS1iHH3CwnkhKZXO5V2N1Vxvq1bd2G3NRAHR1yO5n_I5wlEKhd4g2Vg41OQQN-BYQYhMrQXpaVgE7qD8KdATKO0ohShDZOR5M7TmmfNIm7CclN2pjyZyW8Q10TVssgzFzYwYxWnTUMO380iQgZXNHrwUFEnuSrMeJ19zl2u7ofaFKcqm9KTsKUKagm8O_N-GAMDDbWwxu8jMvLmCzVhwBEFculggzzQzUtPoR9EF1HMRYQN9hWmNWpmCcC-_yJUjn4A
#！！！手工，用firefox打开https://master01:32576，把上面的token填入提示

