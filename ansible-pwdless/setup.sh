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
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC4yyNn6dQtEGAv0GyDyN/8/lvUcgc6u6QylXF2XKjJQbCBO+l+0AVh9tADH+AyeCf0u1Azh7VmC9TEMRoB6FxrnJcCYSfvKkXdWZ/ODn0nMjDbW/WEFz2ypgS/ooDf0ad/frtdlcTYy7FNfJ/cRJRXJYHytyKVzjCphZ0p0KhhOSNpeJBIWALhDEZk/us+LpUYdQ7TwInsf0/4vcqfpC8hyKyrVBqXUJImEyZJP1Pni5RPmWAsal9vbZw3gjfQJkMsO/u6pEZ6S8SloKNdzwRqZHlasInM3IrJ1E9MZwzkDVbzJzy1iS2cxBkE7xzguHjapIjkIYyH1ZXCb22qtdLFW9rswokCxvjhrNgHROrN7pOVpvOWC5vHQ9M/0lhZY9NqWh8yTISY3v0+Q/Qj55QGAbdjQc1D9uWIvvaU0u3xQc4QskplJS+U1oICwx/GThdLoxamk/Jlar3xeSDNLkxyU2YxbRkVEgCYvv5eB/JK5JP/STgbu3A9sCTb7wZmWNE= apple@localhost

#被控主机
ansible all -m shell -a"rm -rf /root/.ssh/"

#mac控制点到被控主机，因为sshpass安装路径原因，playbook需要修改
sudo ansible-playbook -i hosts-cp non_interactive/ansible_setup_passwordless_ssh.yml.mac

#被控主机之间免密
sudo ansible-playbook -i hosts non_interactive/ansible_setup_passwordless_ssh.yml.linux

