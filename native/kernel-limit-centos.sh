ansible all -m shell -a"echo
"
#each working node
ulimit -a|grep 'open files' && ulimit -a|grep 'max user processes' && sysctl -a|grep 'vm.max_map_count'
:<<EOF
mdlapubu | CHANGED | rc=0 >>
open files                      (-n) 1024
max user processes              (-u) 127466
vm.max_map_count = 65530
dtpct | CHANGED | rc=0 >>
open files                      (-n) 1024
max user processes              (-u) 256321
vm.max_map_count = 65530
mdubu | CHANGED | rc=0 >>
open files                      (-n) 1024
max user processes              (-u) 127768
vm.max_map_count = 65530
EOF

#files
find / -name pam_limits.so
file=/etc/pam.d/login
#each working node
cp ${file} ${file}.bk-4-files-no-limitation.d-`date +%Y-%m-%d`-t-`date +%H-%M-%S`
cat << \EOF >> ${file}
session required /usr/lib64/security/pam_limits.so
EOF

file=/etc/security/limits.conf
#centos, each working node
cp ${file} ${file}.bk-4-files-no-limitation.d-`date +%Y-%m-%d`-t-`date +%H-%M-%S`
cat << \EOF >> ${file}
* soft nofile 65535
* hard nofile 65535
EOF

file=/etc/sysctl.conf
#centos, each working node
cp ${file} ${file}.bk-4-files-no-limitation.d-`date +%Y-%m-%d`-t-`date +%H-%M-%S`
cat << \EOF >> ${file}
fs.file-max = 6553500
EOF

file=/etc/systemd/system.conf
cp ${file} ${file}.bk-4-files-no-limitation.d-`date +%Y-%m-%d`-t-`date +%H-%M-%S`
sed -i '/^#DefaultLimitNOFILE=/aDefaultLimitNOFILE=65535' ${file}


#processes
file=/etc/security/limits.d/20-nproc.conf
#centos, each working node
cp ${file} ${file}.bk-4-files-no-limitation.d-`date +%Y-%m-%d`-t-`date +%H-%M-%S`
sed -i 's/*          soft    nproc     4096/*          soft    nproc     655350/g' ${file}


file=/etc/systemd/system.conf
#centos, each working node
cp ${file} ${file}.bk-4-processes-no-limitation.d-`date +%Y-%m-%d`-t-`date +%H-%M-%S`
sed -i '/^#DefaultLimitNPROC=/aDefaultLimitNPROC=655350' ${file}


#VMA(virutal memory area)counts
file=/etc/sysctl.conf
#centos, each working node
cp ${file} ${file}.bk-4-VMA-no-limitation.d-`date +%Y-%m-%d`-t-`date +%H-%M-%S`
cat << \EOF >> ${file}
vm.max_map_count=2097152
EOF


#each working node
sync;reboot now


#each working node
ulimit -a|grep 'open files' && ulimit -a|grep 'max user processes' && sysctl -a|grep 'vm.max_map_count'
:<<EOF
mdlapubu | CHANGED | rc=0 >>
open files                      (-n) 65535
max user processes              (-u) 655350
vm.max_map_count = 2097152
dtpct | CHANGED | rc=0 >>
open files                      (-n) 65535
max user processes              (-u) 655350
vm.max_map_count = 2097152
mdubu | CHANGED | rc=0 >>
open files                      (-n) 65535
max user processes              (-u) 655350
vm.max_map_count = 2097152
EOF
