kubectl get podpreset
#if return, error: the server doesn't have a resource type "podpreset", then should be enabled first
file=/etc/kubernetes/manifests/kube-apiserver.yaml
sudo cp ${file} ${file}.bk
sudo ansible masterk8s -m shell -a"cp ${file} ${file}.bk"
sudo ansible masterk8s -m shell -a"cat ${file}"
sudo ansible masterk8s -m shell -a"sed -i 's@    - --enable-admission-plugins=NodeRestriction@    - --enable-admission-plugins=NodeRestriction,PodPreset@g' ${file}"
sudo ansible masterk8s -m shell -a"sed -i '/    - --enable-admission-plugins/a\    - --runtime-config=settings.k8s.io/v1alpha1=true' ${file}"
sudo ansible masterk8s -m shell -a"cat ${file}"
kubectl get podpreset

#不知道为什么，改了以上设置以后，podpreset还是没有启用
:<<EOF
    volumeMounts:
      - name: mytz-config
        mountPath: /etc/localtime
  volumes:
    - name: mytz-config
      hostPath:
        path: /usr/share/zoneinfo/Asia/Shanghai
EOF