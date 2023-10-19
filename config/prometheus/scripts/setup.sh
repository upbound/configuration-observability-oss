#!/bin/bash

SCRIPT_DIR=$( cd -- $( dirname -- "${BASH_SOURCE[0]}" ) &> /dev/null && pwd )

kubectl apply -f ${SCRIPT_DIR}/../../../test/provider/aws.yaml

PROMETHEUS_POD=$(kubectl -n operators get pods|grep kube-prome-prometheus|awk {'print $1'})

kubectl -n operators port-forward ${RPOMETHEUS_POD} 9090 &
