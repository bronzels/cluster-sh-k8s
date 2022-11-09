#安装xcode

#参考此文章安装command line developer tools
#
git version

#安装brew，选北师大镜像，确保中间安装过程没有报错
/bin/zsh -c "$(curl -fsSL https://gitee.com/cunkai/HomebrewCN/raw/master/Homebrew.sh)"

#替换brew源为中科大
# 替换各个源
git -C "$(brew --repo)" remote set-url origin https://mirrors.ustc.edu.cn/brew.git
git -C "$(brew --repo homebrew/core)" remote set-url origin https://mirrors.ustc.edu.cn/homebrew-core.git
git -C "$(brew --repo homebrew/cask)" remote set-url origin https://mirrors.ustc.edu.cn/homebrew-cask.git
# zsh 替换 brew bintray 镜像
echo 'export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.ustc.edu.cn/homebrew-bottles' >> ~/.zshrc
source ~/.zshrc
# bash 替换 brew bintray 镜像
echo 'export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.ustc.edu.cn/homebrew-bottles' >> ~/.bash_profile
source ~/.bash_profile
# 刷新源
brew update

#替换回官方源
# 重置 brew.git 为官方源
git -C "$(brew --repo)" remote set-url origin https://github.com/Homebrew/brew.git
# 重置 homebrew-core.git 为官方源
git -C "$(brew --repo homebrew/core)" remote set-url origin https://github.com/Homebrew/homebrew-core.git
# 重置 homebrew-cask.git 为官方源
git -C "$(brew --repo homebrew/cask)" remote set-url origin https://github.com/Homebrew/homebrew-cask
# zsh 注释掉 HOMEBREW_BOTTLE_DOMAIN 配置
vi ~/.zshrc
# export HOMEBREW_BOTTLE_DOMAIN=xxxxxxxxx
# bash 注释掉 HOMEBREW_BOTTLE_DOMAIN 配置
vi ~/.bash_profile
# export HOMEBREW_BOTTLE_DOMAIN=xxxxxxxxx
# 刷新源
brew update

# 刷新源
$ brew update


brew install wget coreutils telnet watch
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
sudo -s
sudo echo 'export PATH=$PATH:.:/Users/apple/bin' >> /etc/bashrc

cd /Volumes/data/Applications/
tar xzvf ~/Downloads/apache-maven-3.8.6-bin.tar.gz
sudo -s
sudo echo 'export PATH=$PATH:/Volumes/data/Applications/apache-maven/bin' >> /etc/bashrc

sudo -s
sudo echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/bashrc
cat >> ~/.bash_profile << EOF
export GOPATH=/Volumes/data/workspace/gopath
export GOPROXY=https://goproxy.cn
EOF

sudo -s
sudo echo 'export PATH=$PATH:/Library/Java/JavaVirtualMachines/jdk1.8.0_351.jdk/Contents/Home/bin' >> /etc/bashrc
cat >> ~/.bash_profile << EOF
export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk1.8.0_351.jdk/Contents/Home/
export CLASSPATH=\$JAVA_HOME/lib/tools.jar:\$JAVA_HOME/lib/dt.jar:.
EOF

#mpi安装
brew install mpich

#mac sed是bsd，和gnu行为区别很大，很多shell历史上linux好用的mac下不好用了
brew install gnu-sed
sudo -s
sudo echo 'export PATH=$PATH:/usr/local/opt/gnu-sed/libexec/gnubin' >> /etc/bashrc

brew install gradle
echo "export GRADLE_OPTS=-Dgradle.user.home=/Volumes/data/gradle_cache" >> ~/.bash_profile

#mac
brew install minio/stable/mc