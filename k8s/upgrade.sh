#cp
kubeadm version
    kubeadm version: &version.Info{Major:"1", Minor:"21", GitVersion:"v1.21.14", GitCommit:"0f77da5bd4809927e15d1658fb4aa8f13ad890a5", GitTreeState:"clean", BuildDate:"2022-06-15T14:16:13Z", GoVersion:"go1.16.15", Compiler:"gc", Platform:"linux/amd64"}
yum list --showduplicates kubeadm --disableexcludes=kubernetes
yum install -y kubeadm-1.24.11-0 --disableexcludes=kubernetes