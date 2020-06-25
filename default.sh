
kubectl apply -f https://raw.githubusercontent.com/coreos/prometheus-operator/v0.39.0/bundle.yaml
#kubectl delete -f https://raw.githubusercontent.com/coreos/prometheus-operator/v0.39.0/bundle.yaml
kubectl get pod |grep prometheus

:<<EOF
helm install mynfserv stable/nfs-server-provisioner \
  --set service.type=NodePort \
  --set service.rpcbindNodePort=30048 \
  --set storageClass.name="mynfs"

NOTES:
The NFS Provisioner service has now been installed.

A storage class named 'mynfs' has now been created
and is available to provision dynamic volumes.

You can use this storageclass by creating a `PersistentVolumeClaim` with the
correct storageClassName attribute. For example:

    ---
    kind: PersistentVolumeClaim
    apiVersion: v1
    metadata:
      name: test-dynamic-volume-claim
    spec:
      storageClassName: "mynfs"
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 100Mi
EOF
