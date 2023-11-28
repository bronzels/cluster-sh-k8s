git clone git@github.com:ilias-sp/ansible-setup-passwordless-ssh.git

#清理过去的ssh文件
#cp
rm -rf ~/.ssh
#mac
sudo rm -rf /var/root/.ssh/
rm -rf /Users/apple/.ssh
#linux
sudo rm -rf /root/.ssh/
#重新生成密钥
ssh-keygen
cat /Users/apple/.ssh/id_rsa.pub
#密钥copy到github
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDfnDsRLKMhwCFWwnDWxnmRe5gmn/TCHT/gzp3hz+73QCiNST2LCKPOPTfX1El7mt3wtRk11Id6KKmwRe9uBwq3M9iLeRzGsRe3ZbaA9+ag0BRdIevl4a4ava1mgesTJvoih0PSpPSyHgsnnZm4OM/+/bPxM5YV4qtJgg7Ef7/NjSPPjw6db5oCTqAuYx4L85QJGlzytOBCIZrWBZqNYlGnh1Pp0XJvuY6y+YBt0/rvJ8HdzBzV2wi0C7gle+EVVWibpfXtpke0jGuMVrGlrRQi6ArtJ4IFoajJpSvT1wyPoUeRxlcXeyov9PnmRsUa9rgDpFqIfzId7Z4tJc68a1ciQBbBJ5DdF9C8PU+UVwc/p7KVRpn2dJakaUzi5tziRuWbR8aQz8B1z5xvofa5RgIJiv6ovJ7n2y0qy3S9Tk2G8d6uIKNEJ5QdpJ69/SAsKQkjuE2YTr+TaYUTpjZRXcu6oXLHRmJd0nCOAYmg/Hg6B7Wkn9K4Imd2NdPYlg4bq3k= apple@localhost

#被控主机
ansible all -m shell -a"rm -rf /root/.ssh/"

#mac控制点到被控主机，因为sshpass安装路径原因，playbook需要修改
sudo ansible-playbook -i hosts-cp non_interactive/ansible_setup_passwordless_ssh.yml.mac

#被控主机之间免密
sudo ansible-playbook -i hosts non_interactive/ansible_setup_passwordless_ssh.yml.linux

