ansible all -m shell -a"date"
ansible all -m shell -a"systemctl status chronyd"
ansible all -m shell -a"sudo ls /"
ansible all -m shell -a"yum install -y curl tar"

sudo/curl/openssl/tar