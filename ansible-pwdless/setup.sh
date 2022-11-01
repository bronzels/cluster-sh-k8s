git clone git@github.com:ilias-sp/ansible-setup-passwordless-ssh.git

#被控主机之间免密
ansible-playbook -i hosts non_interactive/ansible_setup_passwordless_ssh.yml.ubu

#mac控制点到被控主机，因为sshpass安装路径原因，playbook需要修改
ansible-playbook -i hosts-cp non_interactive/ansible_setup_passwordless_ssh.yml.mac
