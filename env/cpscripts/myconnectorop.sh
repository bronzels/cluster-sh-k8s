ns=$1
name=$2

if [ ${op} == "start" ]; then
  op=resume
else
  op=pause
fi

kubectl run curl-json -it --image=radial/busyboxplus:curl --restart=Never --rm -- curl -s -X PUT myconnsvc.${ns}-${name}:8083/myconn/${op}
