#master
#root
ssh-keyscan master02 >> ~/.ssh/known_hosts
cp ~/ssh-addkey.yml ~/ssh-addkey-newgrp.yml
sed -i 's@all@newgrp@g' ~/ssh-addkey-newgrp.yml
ansible-playbook -i /etc/ansible/hosts ~/ssh-addkey-newgrp.yml

ansible newgrp -m shell -a"cp /etc/hosts /etc/hosts.bk"
ansible newgrp -m copy -a"src=/etc/hosts dest=/etc"


#master
#ubuntu
ssh-keyscan master02 >> ~/.ssh/known_hosts
cp ~/ssh-addkey.yml ~/ssh-addkey-newgrp.yml
sed -i 's@all@newgrp@g' ~/ssh-addkey-newgrp.yml
ansible-playbook -i /etc/ansible/hosts ~/ssh-addkey-newgrp.yml

ansible newgrp -m shell -a"cat /etc/issue"
ansible newgrp -m shell -a"uname -r"







