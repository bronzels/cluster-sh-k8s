mkdir confluent-operator
wget -c https://platform-ops-bin.s3-us-west-1.amazonaws.com/operator/confluent-operator-5.5.0.tar.gz
mv ../confluent-operator-5.5.0.tar.gz ./
tar xzvf confluent-operator-5.5.0.tar.gz
cp helm/providers/private.yaml my-values.yaml

export VALUES_FILE=$PWD/my-values.yaml

cd
helm install \
  operator \
  ./confluent-operator \
  --values $VALUES_FILE \
  --namespace operator \
  --set operator.enabled=true


