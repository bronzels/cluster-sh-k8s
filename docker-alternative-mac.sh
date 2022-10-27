#写在docker desktop
#buildkit
brew install buildkit

#nerdctl
brew install lima
limactl start
lima nerdctl run -d --name nginx -p 127.0.0.1:8080:80 nginx:alpine

