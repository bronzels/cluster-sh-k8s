git clone git@github.com:ilias-sp/ansible-setup-passwordless-ssh.git

#清理过去的ssh文件
#cp
rm -rf ~/.ssh
#mac
sudo rm -rf /var/root/.ssh/
#linux
rm -rf /Users/apple/.ssh
sudo rm -rf /root/.ssh/
#重新生成密钥
ssh-keygen
cat /Users/apple/.ssh/id_rsa.pub
#密钥copy到github

#被控主机
ansible all -m shell -a"rm -rf /root/.ssh/"

#mac控制点到被控主机，因为sshpass安装路径原因，playbook需要修改
sudo ansible-playbook -i hosts-cp non_interactive/ansible_setup_passwordless_ssh.yml.mac

#被控主机之间免密
sudo ansible-playbook -i hosts non_interactive/ansible_setup_passwordless_ssh.yml.linux

