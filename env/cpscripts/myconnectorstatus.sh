ns=$1
name=$2

kubectl run curl-json -it --image=radial/busyboxplus:curl --restart=Never --rm -- curl myconnsvc.${ns}-${name}:8083/myconn/status
