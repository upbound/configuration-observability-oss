#!/bin/bash

SCRIPT_DIR=$( cd -- $( dirname -- "${BASH_SOURCE[0]}" ) &> /dev/null && pwd )
make e2e
kubectl apply -f ${SCRIPT_DIR}/../test/provider/aws.yaml
kubectl wait provider.pkg --all --for condition=Healthy --timeout=15m 2>/dev/null

${SCRIPT_DIR}/prometheus-make-provider-service.sh
kubectl apply -f ${SCRIPT_DIR}/../.up/examples/oss.yaml

OPERATORS_NAMESPACE=""
while [[ "${OPERATORS_NAMESPACE}" == "" ]]; do
    sleep 3
    OPERATORS_NAMESPACE=$(kubectl get namespace|grep operators|awk '{print $1}')
done

kubectl apply -f ${SCRIPT_DIR}/../.up/config/operators
kubectl apply -f ${SCRIPT_DIR}/../.up/config/crossplane
kubectl apply -f ${SCRIPT_DIR}/../.up/config/crossplane-rbac-manager

PROMETHEUS_READY=""
while [[ "${PROMETHEUS_READY}" == "" ]]; do
    sleep 3
    PROMETHEUS_READY=$(kubectl wait -n operators \
	--for=condition=Ready pod \
	-l app.kubernetes.io/name=prometheus \
	2>/dev/null)
done
