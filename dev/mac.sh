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
exit

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
exit
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
exit

brew install gradle
echo "export GRADLE_OPTS=-Dgradle.user.home=/Volumes/data/gradle_cache" >> ~/.bash_profile

#minio cli client
brew install minio/stable/mc

#nfs server
sudo -s
sudo echo "/Volumes/data/nfs -alldirs -maproot=root:wheel -network 192.168.3.0 -mask 255.255.255.0" >> /etc/exports
exit
chmod 755 /Volumes/data/nfs
sudo nfsd enable
sudo nfsd restart
sudo nfsd status
cd /Volumes/data
mkdir testmnt
mount -t nfs -o nolock 192.168.3.9:/Volumes/data/nfs /Volumes/data/testmnt
echo "hello" > testmnt/x
cat testmnt/x
umount testmnt
rm -rf testmnt

#redis client
brew install redis

#cubefs等网络文件系统挂载
brew install osxfuse

#exfat挂载
brew install diskutil
diskutil list
sudo mount -t exfat -o rw,nobrowse /dev/disk4s4 /Volumes/mdexf
umount /Volumes/mdexf
#数据盘同步备份
sudo rsync -avP data data0/

#工具卸载pkg
#https://www.corecode.io/uninstallpkg/
#解压到/Applications/目录
xattr -d com.apple.quarantine /Applications/UninstallPKG.app

#minio安装
brew install minio/stable/minio
wget -c https://dl.min.io/client/mc/release/darwin-amd64/mc -P /Users/apple/bin/
wget -c https://dl.min.io/server/minio/release/darwin-amd64/minio -P /Users/apple/bin/
chmod +x /Users/apple/bin/mc
:<<EOF
mkdir /Volumes/data/miniodata
chmod -R 777 /Volumes/data/miniodata
nohup minio server /Volumes/data/miniodata > mac_minio_server.log 2>&1 &
#很难下载
#报错：dyld[62265]: symbol not found in flat namespace ()
EOF
docker pull minio/minio
lsof -nP -p 9000 | grep LISTEN
lsof -nP -p 9091 | grep LISTEN
docker run -d \
  -p 9000:9000 \
  -p 9091:9091 \
  --name=minio \
  --restart=always \
  -e "MINIO_ACCESS_KEY=admin" \
  -e "MINIO_SECRET_KEY=admin123" \
  -v /Volumes/data/minio/data:/data \
  -v /Volumes/data/minio/.minio:/root/.minio \
  minio/minio server /data --console-address ":9091" --address ":9000"

#colima（代替docker desktop）
brew install docker docker-compose
brew install colima
colima start --edit
#在docker: {}的大括号里，填入daemon.json的内容
docker info
#检查最后的Insecure Registries:，Registry Mirrors:，确认镜像和私仓已经正确设置，这时候下载image应该MB/s的速度

#gpg验证安装包
brew install gpg

#spark编译需要
brew install scala@2.12
cd /usr/local/opt/
ln -s scala@2.12 scala
sudo -s
sudo echo 'export PATH=$PATH:/usr/local/opt/scala/bin' >> /etc/bashrc
sudo echo 'export SCALA_HOME=/usr/local/opt/scala/bin' >> /etc/bashrc
exit
scala -help
brew install xquartz --cask

#最多进程
ulimit -a|grep 'max user processes'
#max user processes                  (-u) 1392
#每个进程最多打开文件数
ulimit -a|grep 'open files'
#open files                          (-n) 256
sudo -s
cat >> /Library/LaunchDaemons/limit.maxfiles.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
  <plist version="1.0">
    <dict>
      <key>Label</key>
        <string>limit.maxfiles</string>
      <key>ProgramArguments</key>
        <array>
          <string>launchctl</string>
          <string>limit</string>
          <string>maxfiles</string>
          <string>65536</string>
          <string>65536</string>
        </array>
      <key>RunAtLoad</key>
        <true/>
      <key>ServiceIPC</key>
        <false/>
    </dict>
  </plist>
EOF
cat >> /Library/LaunchDaemons/limit.maxproc.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple/DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
  <plist version="1.0">
    <dict>
      <key>Label</key>
        <string>limit.maxproc</string>
      <key>ProgramArguments</key>
        <array>
          <string>launchctl</string>
          <string>limit</string>
          <string>maxproc</string>
          <string>2048</string>
          <string>2048</string>
        </array>
      <key>RunAtLoad</key>
        <true />
      <key>ServiceIPC</key>
        <false />
    </dict>
  </plist>
EOF
exit

#r安装镜像设置
#下载安装pkg包
cat >> ~/.Rprofile << EOF
local({
    r <- getOption("repos")
    r["CRAN"] <- "https://mirrors.tuna.tsinghua.edu.cn/CRAN/"
    r["BioC_mirror"] <- "https://mirrors.ustc.edu.cn/CRAN/"
    options(repos = r)
})
EOF
#构建spark依赖
brew install pandoc
#brew install mactex --cask
brew install basictex --cask
#重启shell
whichis pdflatex


#k8s资源命令行管理
brew tap robscott/tap
brew install robscott/tap/kube-capacity


#doris broker编译依赖
#cmake安装
sudo "/Applications/CMake.app/Contents/bin/cmake-gui" --install=/Users/apple/bin
cmake -version
#byacc/automake/pcre/bison安装
brew install byacc automake pcre bison


#k8s相关shell脚本，解析yaml
#jq安装
brew install jq


#编译doris-spark-connector依赖
#thrift安装
brew tap-new $USER/local-tap
brew extract --version='0.13.0' thrift $USER/local-tap
brew install thrift@0.13.0
thrift -version
brew install gnu-getopt
gnu-getopt
