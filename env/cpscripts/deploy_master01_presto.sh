#如果是项目定制开发的presto plugin部分有修改，把k8sdeploy.sh打包生成k8sdeploy.tar.gz上传到跳板机
#ubuntu
cd ~

tar xzvf /tmp/k8sdeploy.tar.gz

cp -rf k8sdeploy_dir/comprplg ~/charts/stable/presto