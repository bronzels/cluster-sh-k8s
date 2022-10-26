#安装xcode

#参考此文章安装command line developer tools
#
git version

#安装brew，选北师大镜像，确保中间安装过程没有报错
/bin/zsh -c "$(curl -fsSL https://gitee.com/cunkai/HomebrewCN/raw/master/Homebrew.sh)"

brew install wget coreutils
echo 'alias date=gdate' >>~/.bash_profile

#避免idea死住问题
scutil --set HostName "localhost"

#参考文章打开root权限
#https://www.bbsmax.com/topic/mac%E4%B8%8A%E6%8A%8A%E7%94%A8%E6%88%B7%E8%B5%8B%E4%BA%88wheel/

#把用户加入wheel组
#su进入root
dseditgroup -o edit -a apple -t user wheel
groups user_name

#sudo不输入密码
#/etc/sudoers
:<<EOF
把
#%admin  ALL=(ALL)         NOPASSWD: ALL
#改成
%admin  ALL=(ALL)         NOPASSWD: ALL
%wheel  ALL=(ALL)         NOPASSWD: ALL
EOF

#打开hosts组写入权限
sudo chmod g+w /etc/hosts

#参考文章切换成bash
#https://www.cnblogs.com/sundaysgarden/p/16287489.html
#版本高于4.1+
echo $BASH_VERSION
brew install bash
#需要参考以上文章路径从/bin/bash改到/usr/local/bin/bash
echo $BASH_VERSION
echo "export CLICOLOR=1" >> ~/.bash_profile
echo "export LSCOLORS=GxFxCxDxBxegedabagaced" >> ~/.bash_profile

#增加用户path
echo 'export PATH=$PATH:.:/Users/apple/bin' >> /etc/.bashrc

