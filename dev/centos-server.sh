yum install nfs-utils rpcbind -y
systemctl enable rpcbind.service
systemctl enable nfs-server
echo "/workspace     *(rw,sync,no_root_squash,no_subtree_check)" > /etc/exports
showmount -e dtpct
systemctl restart rpcbind.service
systemctl restart nfs-server

sed -i 's/^SELINUX=enforcing$/SELINUX=disabled/' /etc/selinux/config
systemctl stop firewalld
systemctl disable firewalld
systemctl stop firewalld.service
systemctl disable firewalld.service

swapoff -a
#修改/etc/fstab文件，注释掉swap分区一行
#/dev/mapper/centos-swap swap                    swap    defaults        0 0

cat << \EOF > ~/.bashrc
export PATH=$PATH:/usr/local/cuda/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda/lib64
eval "$(/data0/miniconda3/bin/conda shell.bash hook)"

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/data0/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/data0/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/data0/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/data0/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

#conda activate airflow

export TENSORRT_DIR=/data0/trt
export PATH=$PATH:$TENSORRT_DIR/bin
export LD_LIBRARY_PATH=$TENSORRT_DIR/lib:$LD_LIBRARY_PATH
#source scl_source enable devtoolset-7
#source scl_source enable devtoolset-10
source scl_source enable devtoolset-11
export PATH=/data0/cmake/bin:$PATH
export CUTLASS_PATH=/data0/cutlass

export HF_ENDPOINT=https://hf-mirror.com
export HF_HOME=/workspace/hfcache
export HF_DATASETS_CACHE=$HF_HOME/datasets
export HUGGINGFACE_HUB_CACHE=$HF_HOME/hub
export TRANSFORMERS_CACHE=$HF_HOME/hub
export HF_METRICS_CACHE=$HF_HOME/metrics
export HF_EVALUATE_CACHE=$HF_HOME/evaluate
export HF_MODULES_CACHE=$HF_HOME/modules/evaluate_modules
export DIFFUSERS_CACHE=$HF_HOME/diffusers
EOF

rsync -av mdubu:/data0/cuda /data0/
ln -s /data0/cuda/cuda-12.1 /usr/local/cuda
#安装nvida-container
rsync -av mdubu:/data0/cutlass /data0/

rsync -av mdubu:/data0/miniconda3 /data0/
scp mdubu:/data0/condarc /data0/
ln -s /data0/condarc /root/.condarc
rsync -av mdubu:/data0/envs /data0/

rsync -av mdubu:/data0/TensorRT-8.6.1.6 /data0/
ln -s /data0/TensorRT-8.6.1.6 /data0/trt
rsync -av mdubu:/data0/cmake /data0/

yum install -y epel-release centos-release-scl scl-utils
yum install -y devtoolset-7 devtoolset-10 devtoolset-11
yum install -y automake autoconf libtool
yum install -y kernel-devel tar wget

gcc --version
make --version

yum install -y zip unzip
yum install -y openssl openssh-server openssh-clients
yum install -y ansible sshpass


rsync -av mdubu:/data0/cache /data0/cache
ln -s /data0/cache /root/.cache

yum install curl-devel expat-devel gettext-devel openssl-devel zlib-devel -y
yum install perl-ExtUtils-MakeMaker -y
GIT_VERSION=2.45.0
wget -c https://github.com/git/git/archive/refs/tags/v2.45.0.tar.gz -O git-${GIT_VERSION}.tar.gz
tar -xzf git-${GIT_VERSION}.tar.gz
cd git-${GIT_VERSION}
#conda activate sd，要在虚拟环境下编译
make -j$(nproc --all) prefix=/usr/local all
make prefix=/usr/local install
cd ..
git version

