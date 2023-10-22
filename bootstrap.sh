#!/bin/bash

make e2e
kubectl apply -f test/provider/aws.yaml
kubectl wait provider.pkg --all --for condition=Healthy --timeout=15m 2>/dev/null

config/prometheus/scripts/make-provider-service.sh
kubectl apply -f examples/oss.yaml

OPERATORS_NAMESPACE=""
while [[ "${OPERATORS_NAMESPACE}" == "" ]]; do
    sleep 3
    OPERATORS_NAMESPACE=$(kubectl get namespace|grep operators|awk '{print $1}')
done

kubectl apply -f config/operators-config
sleep 5
kubectl wait -n operators --for=condition=Ready pod -l app.kubernetes.io/name=prometheus
