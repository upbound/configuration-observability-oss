#!/bin/bash

make e2e
kubectl apply -f test/provider/aws.yaml
kubectl wait provider.pkg --all --for condition=Healthy --timeout=15m 2>/dev/null
# WAIT until providers are ready
config/prometheus/scripts/make-provider-service.sh
kubectl apply -f examples/oss.yaml
sleep 15
kubectl apply -f config/prometheus/operators-config


echo kubectl -n port-forward <prometheus-pod> 9090
echo curl http://localhost:9090/targets
