if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Mac detected."
    #mac
    MYHOME=/Volumes/data
    BININSTALLED=/Users/apple/bin
    os=darwin
    SED=gsed
else
    echo "Assuming linux by default."
    #linux
    MYHOME=~
    BININSTALLED=~/bin
    os=linux
    SED=sed
fi

CELEROHOME=${MYHOME}/workspace/cluster-sh-k8s/k8s-celero
rev=1.10.0
wget -c https://github.com/vmware-tanzu/velero/releases/download/v${rev}/velero-v${rev}-${os}-amd64.tar.gz
tar zxvf velero-v${rev}-${os}-amd64.tar.gz
mv velero-v${rev}-${os}-amd64/velero ${BININSTALLED}/
ln -s velero-v1.10.0-darwin-amd64 velero

cat << EOF > credentials-velero
[default]
aws_access_key_id = admin
aws_secret_access_key = admin123
EOF
velero install \
    --provider aws \
    --plugins velero/velero-plugin-for-aws:v1.4.1 \
    --bucket velero \
    --secret-file ./credentials-velero \
    --use-volume-snapshots=false \
    --backup-location-config region=minio,s3ForcePathStyle="true",s3Url=http://localhost:9000